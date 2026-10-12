package dev.aurora.aurora_vpn.vpn

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.VpnService
import android.net.wifi.WifiManager
import android.os.Build
import android.os.ParcelFileDescriptor
import android.os.Process
import android.system.OsConstants
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import androidx.core.content.ContextCompat
import dev.aurora.aurora_vpn.MainActivity
import dev.aurora.aurora_vpn.R
import io.nekohasekai.libbox.BridgeOptions
import io.nekohasekai.libbox.BridgeSession
import io.nekohasekai.libbox.CommandClient
import io.nekohasekai.libbox.CommandClientHandler
import io.nekohasekai.libbox.CommandClientOptions
import io.nekohasekai.libbox.CommandServer
import io.nekohasekai.libbox.CommandServerHandler
import io.nekohasekai.libbox.ConnectionEvents
import io.nekohasekai.libbox.ConnectionOwner
import io.nekohasekai.libbox.InterfaceUpdateListener
import io.nekohasekai.libbox.Libbox
import io.nekohasekai.libbox.LocalDNSTransport
import io.nekohasekai.libbox.LogIterator
import io.nekohasekai.libbox.NeighborUpdateListener
import io.nekohasekai.libbox.NetworkInterfaceIterator
import io.nekohasekai.libbox.OutboundGroupItemIterator
import io.nekohasekai.libbox.OutboundGroupIterator
import io.nekohasekai.libbox.OverrideOptions
import io.nekohasekai.libbox.PlatformInterface
import io.nekohasekai.libbox.PlatformUser
import io.nekohasekai.libbox.SetupOptions
import io.nekohasekai.libbox.ShellSession
import io.nekohasekai.libbox.StatusMessage
import io.nekohasekai.libbox.StringIterator
import io.nekohasekai.libbox.SystemProxyStatus
import io.nekohasekai.libbox.TunOptions
import io.nekohasekai.libbox.WIFIState
import io.nekohasekai.xraybridge.Xraybridge
import java.net.Inet6Address
import java.net.InetSocketAddress
import java.net.NetworkInterface
import java.util.concurrent.Executors
import io.nekohasekai.libbox.Notification as BoxNotification
import io.nekohasekai.libbox.NetworkInterface as BoxInterface

/**
 * Android tunnel: VpnService + sing-box (libbox).
 *
 * Start/stop work runs on a single background thread so requests are applied
 * in order; libbox calls back into [PlatformInterface] from Go threads.
 */
class AuroraVpnService : VpnService(), PlatformInterface, CommandServerHandler {

    companion object {
        private const val TAG = "AuroraVpn"
        const val ACTION_START = "dev.aurora.vpn.START"
        const val ACTION_STOP = "dev.aurora.vpn.STOP"
        private const val CHANNEL_ID = "vpn_status"
        private const val NOTIFICATION_ID = 1

        /** True once Libbox.setup ran in this process. */
        @Volatile var libboxReady = false
            private set

        fun start(context: Context) {
            ContextCompat.startForegroundService(
                context,
                Intent(context, AuroraVpnService::class.java).setAction(ACTION_START),
            )
        }

        fun stop(context: Context) {
            if (VpnHub.status == VpnStatus.STOPPED) return
            context.startService(Intent(context, AuroraVpnService::class.java).setAction(ACTION_STOP))
        }

        /** Libbox.setup must run once per process before any other call. */
        @Synchronized
        fun setupLibbox(context: Context) {
            if (libboxReady) return
            val work = context.filesDir.resolve("core").apply { mkdirs() }
            Libbox.setup(
                SetupOptions().apply {
                    basePath = context.filesDir.path
                    workingPath = work.path
                    tempPath = context.cacheDir.path
                    fixAndroidStack = Build.VERSION.SDK_INT in 24..28
                    logMaxLines = 3000
                    appVersion = runCatching {
                        context.packageManager.getPackageInfo(context.packageName, 0).versionName
                    }.getOrNull().orEmpty()
                },
            )
            libboxReady = true
        }
    }

    private val worker = Executors.newSingleThreadExecutor { Thread(it, "aurora-vpn") }
    private lateinit var monitor: NetworkMonitor
    private lateinit var resolver: LocalResolver
    private var commandServer: CommandServer? = null
    private var commandClient: CommandClient? = null
    private var tunFd: ParcelFileDescriptor? = null
    private var label = ""
    private var lastNotificationUpdate = 0L

    /**
     * What the user asked for most recently. Start/stop work is queued on
     * [worker] and checks this, so a stop followed by a quick start (or the
     * reverse) ends in the right state instead of racing.
     */
    @Volatile private var wantRunning = false

    override fun onCreate() {
        super.onCreate()
        monitor = NetworkMonitor(this)
        resolver = LocalResolver(monitor)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            wantRunning = false
            enqueue { stopTunnel(null) }
            return START_NOT_STICKY
        }
        // ACTION_START from the app, or android.net.VpnService from Always-on.
        // Every startForegroundService() must be answered with startForeground()
        // — even when we're already running — or Android kills the app.
        label = VpnHub.loadLabel(this)
        val running = VpnHub.status == VpnStatus.STARTED
        showNotification(
            getString(if (running) R.string.notification_connected else R.string.notification_connecting),
            foreground = true,
        )
        wantRunning = true
        enqueue { startTunnel() }
        return START_NOT_STICKY
    }

    override fun onRevoke() {
        // Another VPN took over or the user revoked permission.
        wantRunning = false
        enqueue { stopTunnel(null) }
    }

    override fun onDestroy() {
        wantRunning = false
        enqueue {
            if (VpnHub.status != VpnStatus.STOPPED) stopTunnel(null)
            monitor.close()
        }
        worker.shutdown()
        super.onDestroy()
    }

    /** Runs [block] on the lifecycle thread; never throws (e.g. after shutdown). */
    private fun enqueue(block: () -> Unit) {
        runCatching {
            worker.execute {
                try {
                    block()
                } catch (e: Throwable) {
                    Log.e(TAG, "lifecycle task failed", e)
                }
            }
        }.onFailure { Log.w(TAG, "lifecycle task rejected", it) }
    }

    // --- lifecycle ------------------------------------------------------------

    private fun startTunnel() {
        if (!wantRunning) return
        if (VpnHub.status == VpnStatus.STARTED && commandServer != null) return
        val config = VpnHub.loadConfig(this)
        if (config == null) {
            wantRunning = false
            stopTunnel(getString(R.string.error_no_config))
            return
        }
        VpnHub.setStatus(VpnStatus.STARTING)
        try {
            setupLibbox(this)
            // Xray first: sing-box's SOCKS bridge must have someone to talk to.
            VpnHub.loadXray(this)?.let { Xraybridge.start(it) }
            monitor.start()
            val server = commandServer ?: CommandServer(this, this).also {
                it.start()
                commandServer = it
            }
            // Split-tunnel packages are already in the config's TUN inbound.
            server.startOrReloadService(config, OverrideOptions())
            if (!wantRunning) {
                // Cancelled while starting.
                stopTunnel(null)
                return
            }
            VpnHub.setStatus(VpnStatus.STARTED)
            showNotification(getString(R.string.notification_connected))
            connectClient()
        } catch (e: Throwable) {
            Log.e(TAG, "start failed", e)
            wantRunning = false
            stopTunnel(e.message ?: e.toString())
        }
    }

    private fun stopTunnel(error: String?) {
        if (VpnHub.status != VpnStatus.STOPPED) VpnHub.setStatus(VpnStatus.STOPPING, error)
        runCatching { commandClient?.disconnect() }
        commandClient = null
        runCatching { tunFd?.close() }
        tunFd = null
        commandServer?.let { server ->
            runCatching { server.closeService() }.onFailure { Log.w(TAG, "closeService", it) }
            runCatching { server.close() }
        }
        commandServer = null
        runCatching { Xraybridge.stop() }.onFailure { Log.w(TAG, "xray stop", it) }
        monitor.stop()
        VpnHub.setStatus(VpnStatus.STOPPED, error)
        // A start request queued behind this stop keeps the service alive.
        if (!wantRunning) {
            runCatching { ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_REMOVE) }
            stopSelf()
        }
    }
    /** Subscribes to traffic stats and logs from the command server. */
    private fun connectClient() {
        val options = CommandClientOptions().apply {
            addCommand(Libbox.CommandStatus)
            addCommand(Libbox.CommandLog)
            statusInterval = 1_000_000_000L // ns
        }
        val client = CommandClient(clientHandler, options)
        runCatching { client.connect() }.onFailure { Log.w(TAG, "command client", it) }
        commandClient = client
    }

    private val clientHandler = object : CommandClientHandler {
        override fun connected() {}

        override fun disconnected(message: String?) {}

        override fun setDefaultLogLevel(level: Int) {}

        override fun clearLogs() {}

        // Called from Go without an error channel: an escaping exception
        // would abort the whole process, so these never throw.
        override fun writeLogs(messageList: LogIterator) = guard {
            while (messageList.hasNext()) {
                val entry = messageList.next()
                VpnHub.emit(VpnEvent.Log(entry.level, entry.message))
            }
        }

        override fun writeStatus(message: StatusMessage) = guard {
            if (!message.trafficAvailable) return@guard
            VpnHub.emit(
                VpnEvent.Traffic(message.uplink, message.downlink, message.uplinkTotal, message.downlinkTotal),
            )
            val now = System.currentTimeMillis()
            if (now - lastNotificationUpdate >= 2000 && VpnHub.status == VpnStatus.STARTED) {
                lastNotificationUpdate = now
                showNotification(
                    "${getString(R.string.notification_connected)} · ↓ ${speed(message.downlink)}  ↑ ${speed(message.uplink)}",
                )
            }
        }

        override fun writeGroups(message: OutboundGroupIterator) {}

        override fun writeOutbounds(message: OutboundGroupItemIterator) {}

        override fun initializeClashMode(modeList: StringIterator, currentMode: String) {}

        override fun updateClashMode(newMode: String) {}

        override fun writeConnectionEvents(events: ConnectionEvents) {}
    }

    private fun speed(bytes: Long): String = when {
        bytes >= 1 shl 20 -> "%.1f MB/s".format(bytes / 1048576.0)
        bytes >= 1 shl 10 -> "%.0f KB/s".format(bytes / 1024.0)
        else -> "$bytes B/s"
    }

    // --- notification -----------------------------------------------------------

    /**
     * [foreground] promotes the service (required right after every
     * startForegroundService); later updates only re-post the notification.
     */
    private fun showNotification(text: String, foreground: Boolean = false) = guard {
        val nm = getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            nm.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    getString(R.string.notification_channel),
                    NotificationManager.IMPORTANCE_LOW,
                ).apply { setShowBadge(false) },
            )
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        val open = PendingIntent.getActivity(this, 0, Intent(this, MainActivity::class.java), flags)
        val stop = PendingIntent.getService(
            this,
            1,
            Intent(this, AuroraVpnService::class.java).setAction(ACTION_STOP),
            flags,
        )
        val notification: Notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_vpn)
            .setContentTitle(label.ifEmpty { getString(R.string.app_name_fallback) })
            .setContentText(text)
            .setContentIntent(open)
            .addAction(0, getString(R.string.notification_disconnect), stop)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setShowWhen(false)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .build()
        if (foreground) {
            ServiceCompat.startForeground(
                this,
                NOTIFICATION_ID,
                notification,
                if (Build.VERSION.SDK_INT >= 34) ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE else 0,
            )
        } else if (wantRunning) {
            nm.notify(NOTIFICATION_ID, notification)
        }
    }

    /** Swallows and logs; for code reachable from Go callbacks. */
    private inline fun guard(block: () -> Unit) {
        try {
            block()
        } catch (e: Throwable) {
            Log.e(TAG, "callback failed", e)
        }
    }

    // --- CommandServerHandler -----------------------------------------------------

    override fun serviceStop() {
        wantRunning = false
        enqueue { stopTunnel(null) }
    }

    override fun serviceReload() {
        enqueue {
            val config = VpnHub.loadConfig(this) ?: return@enqueue
            commandServer?.startOrReloadService(config, OverrideOptions())
        }
    }

    override fun getSystemProxyStatus(): SystemProxyStatus = SystemProxyStatus()

    override fun setSystemProxyEnabled(isEnabled: Boolean) {}

    override fun triggerNativeCrash() {}

    override fun writeDebugMessage(message: String?) = guard { Log.d(TAG, message.orEmpty()) }

    override fun connectSSHAgent(): Int = -1

    // --- PlatformInterface --------------------------------------------------------

    override fun localDNSTransport(): LocalDNSTransport = resolver

    override fun usePlatformAutoDetectInterfaceControl(): Boolean = true

    /** Keeps the core's own sockets out of the tunnel. */
    override fun autoDetectInterfaceControl(fd: Int) {
        protect(fd)
    }

    override fun openTun(options: TunOptions): Int {
        if (prepare(this) != null) error("android: VPN permission is missing")
        val builder = Builder()
            .setSession(label.ifEmpty { "Aurora VPN" })
            .setMtu(options.mtu)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) builder.setMetered(false)

        options.inet4Address.let { while (it.hasNext()) it.next().let { a -> builder.addAddress(a.address(), a.prefix()) } }
        options.inet6Address.let { while (it.hasNext()) it.next().let { a -> builder.addAddress(a.address(), a.prefix()) } }

        if (options.autoRoute) {
            if (options.dnsMode.value != Libbox.DNSModeDisabled) {
                val dns = options.dnsServerAddress
                while (dns.hasNext()) builder.addDnsServer(dns.next())
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                val r4 = options.inet4RouteAddress
                if (r4.hasNext()) {
                    while (r4.hasNext()) builder.addRoute(r4.next().toIpPrefix())
                } else if (options.inet4Address.hasNext()) {
                    builder.addRoute("0.0.0.0", 0)
                }
                val r6 = options.inet6RouteAddress
                if (r6.hasNext()) {
                    while (r6.hasNext()) builder.addRoute(r6.next().toIpPrefix())
                } else if (options.inet6Address.hasNext()) {
                    builder.addRoute("::", 0)
                }
                val e4 = options.inet4RouteExcludeAddress
                while (e4.hasNext()) builder.excludeRoute(e4.next().toIpPrefix())
                val e6 = options.inet6RouteExcludeAddress
                while (e6.hasNext()) builder.excludeRoute(e6.next().toIpPrefix())
            } else {
                val r4 = options.inet4RouteRange
                while (r4.hasNext()) r4.next().let { builder.addRoute(it.address(), it.prefix()) }
                val r6 = options.inet6RouteRange
                while (r6.hasNext()) r6.next().let { builder.addRoute(it.address(), it.prefix()) }
            }

            val include = options.includePackage.toList()
            val exclude = options.excludePackage.toList()
            for (pkg in include) {
                runCatching { builder.addAllowedApplication(pkg) }
            }
            // A VpnService can only use one of the two lists.
            if (include.isEmpty()) {
                for (pkg in exclude) {
                    runCatching { builder.addDisallowedApplication(pkg) }
                }
            }
        }

        val pfd = builder.establish() ?: error("android: VPN was not prepared or was revoked")
        tunFd = pfd
        return pfd.fd
    }

    override fun useProcFS(): Boolean = Build.VERSION.SDK_INT < Build.VERSION_CODES.Q

    override fun findConnectionOwner(
        ipProtocol: Int,
        sourceAddress: String,
        sourcePort: Int,
        destinationAddress: String,
        destinationPort: Int,
    ): ConnectionOwner {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) error("android: unsupported")
        val cm = getSystemService(ConnectivityManager::class.java)
        val uid = cm.getConnectionOwnerUid(
            ipProtocol,
            InetSocketAddress(sourceAddress, sourcePort),
            InetSocketAddress(destinationAddress, destinationPort),
        )
        if (uid == Process.INVALID_UID) error("android: connection owner not found")
        val packages = packageManager.getPackagesForUid(uid)?.toList().orEmpty()
        return ConnectionOwner().apply {
            userId = uid
            userName = packages.firstOrNull().orEmpty()
            setAndroidPackageNames(StringArray(packages))
        }
    }

    override fun startDefaultInterfaceMonitor(listener: InterfaceUpdateListener) {
        monitor.setListener(listener)
    }

    override fun closeDefaultInterfaceMonitor(listener: InterfaceUpdateListener) {
        monitor.setListener(null)
    }

    override fun getInterfaces(): NetworkInterfaceIterator {
        val cm = getSystemService(ConnectivityManager::class.java)
        val system = NetworkInterface.getNetworkInterfaces()?.toList().orEmpty()
        val out = mutableListOf<BoxInterface>()
        @Suppress("DEPRECATION")
        for (network in cm.allNetworks) {
            val lp = cm.getLinkProperties(network) ?: continue
            val caps = cm.getNetworkCapabilities(network) ?: continue
            if (caps.hasTransport(NetworkCapabilities.TRANSPORT_VPN)) continue
            val ni = system.find { it.name == lp.interfaceName } ?: continue
            out += BoxInterface().apply {
                name = lp.interfaceName
                index = ni.index
                runCatching { mtu = ni.mtu }
                type = when {
                    caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> Libbox.InterfaceTypeWIFI
                    caps.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> Libbox.InterfaceTypeCellular
                    caps.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> Libbox.InterfaceTypeEthernet
                    else -> Libbox.InterfaceTypeOther
                }
                dnsServer = StringArray(lp.dnsServers.mapNotNull { it.hostAddress })
                gateway = StringArray(
                    lp.routes.filter { it.destination.prefixLength == 0 }
                        .mapNotNull { it.gateway }
                        .filterNot { it.isAnyLocalAddress }
                        .mapNotNull { it.hostAddress },
                )
                addresses = StringArray(
                    ni.interfaceAddresses.map {
                        val host = if (it.address is Inet6Address) {
                            Inet6Address.getByAddress(it.address.address).hostAddress
                        } else {
                            it.address.hostAddress
                        }
                        "$host/${it.networkPrefixLength}"
                    },
                )
                var f = 0
                if (caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)) {
                    f = OsConstants.IFF_UP or OsConstants.IFF_RUNNING
                }
                if (ni.isLoopback) f = f or OsConstants.IFF_LOOPBACK
                if (ni.isPointToPoint) f = f or OsConstants.IFF_POINTOPOINT
                if (ni.supportsMulticast()) f = f or OsConstants.IFF_MULTICAST
                flags = f
                metered = !caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_NOT_METERED)
            }
        }
        return InterfaceArray(out.iterator())
    }

    override fun underNetworkExtension(): Boolean = false

    override fun includeAllNetworks(): Boolean = false

    // Only needed for SSID-based rules, which this client doesn't generate.
    // No error channel to Go, so failures (missing permission) become null.
    override fun readWIFIState(): WIFIState? = runCatching {
        @Suppress("DEPRECATION")
        val info = applicationContext.getSystemService(WifiManager::class.java)?.connectionInfo
            ?: return@runCatching null
        val ssid = info.ssid.orEmpty().removeSurrounding("\"").takeUnless { it == "<unknown ssid>" }.orEmpty()
        WIFIState(ssid, info.bssid.orEmpty())
    }.getOrNull()

    override fun clearDNSCache() {}

    override fun sendNotification(notification: BoxNotification) {}

    override fun cancelNotification(identifier: String, typeID: Int) {}

    override fun startNeighborMonitor(listener: NeighborUpdateListener?) {}

    override fun closeNeighborMonitor(listener: NeighborUpdateListener?) {}

    override fun registerMyInterface(name: String?) {}

    override fun usePlatformShell(): Boolean = false

    override fun checkPlatformShell() = error("not supported")

    override fun openShellSession(
        user: PlatformUser?,
        command: String?,
        environ: StringIterator?,
        term: String?,
        rows: Int,
        cols: Int,
    ): ShellSession = error("not supported")

    override fun lookupUser(username: String?): PlatformUser = error("not supported")

    override fun lookupSFTPServer(): String = error("not supported")

    override fun readSystemSSHHostKey(): String = error("not supported")

    override fun tailscaleHostname(): String = Build.MODEL

    override fun usePlatformBridge(): Boolean = false

    override fun createBridge(options: BridgeOptions?): BridgeSession = error("not supported")
}
