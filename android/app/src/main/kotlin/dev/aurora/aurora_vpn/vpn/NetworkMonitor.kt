package dev.aurora.aurora_vpn.vpn

import android.content.Context
import android.net.ConnectivityManager
import android.net.LinkProperties
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import io.nekohasekai.libbox.InterfaceUpdateListener
import java.net.NetworkInterface

/**
 * Tracks the *underlying* default network (not our own VPN) and reports it to
 * sing-box, which binds outbound sockets to it.
 *
 * Approach after shadowsocks-android / sing-box-for-android (GPLv3): since
 * Android P the default-network callback reports the VPN itself, so on 28+ a
 * NetworkRequest is used to get the real default network.
 */
class NetworkMonitor(context: Context) {
    private val connectivity = context.getSystemService(ConnectivityManager::class.java)
    private val thread = HandlerThread("aurora-network").apply { start() }
    private val handler = Handler(thread.looper)

    @Volatile var defaultNetwork: Network? = null
        private set

    private var listener: InterfaceUpdateListener? = null
    private var registered = false

    private val request = NetworkRequest.Builder()
        .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
        .addCapability(NetworkCapabilities.NET_CAPABILITY_NOT_RESTRICTED)
        .build()

    private val callback = object : ConnectivityManager.NetworkCallback() {
        override fun onAvailable(network: Network) = update(network)

        override fun onCapabilitiesChanged(network: Network, caps: NetworkCapabilities) {
            if (network == defaultNetwork) update(network)
        }

        override fun onLinkPropertiesChanged(network: Network, lp: LinkProperties) {
            if (network == defaultNetwork) update(network)
        }

        override fun onLost(network: Network) {
            if (network == defaultNetwork) update(null)
        }
    }

    @Synchronized
    fun start() {
        if (registered) return
        when {
            Build.VERSION.SDK_INT >= 31 ->
                connectivity.registerBestMatchingNetworkCallback(request, callback, handler)
            Build.VERSION.SDK_INT >= 28 -> connectivity.requestNetwork(request, callback, handler)
            else -> connectivity.registerDefaultNetworkCallback(callback, handler)
        }
        registered = true
        if (defaultNetwork == null) defaultNetwork = connectivity.activeNetwork
    }

    @Synchronized
    fun stop() {
        if (!registered) return
        runCatching { connectivity.unregisterNetworkCallback(callback) }
        registered = false
        defaultNetwork = null
    }

    fun setListener(l: InterfaceUpdateListener?) {
        listener = l
        handler.post { notifyListener(defaultNetwork) }
    }

    fun close() {
        stop()
        thread.quitSafely()
    }

    private fun update(network: Network?) {
        defaultNetwork = network
        notifyListener(network)
    }

    /** Runs on the monitor thread; may retry briefly while the link settles. */
    private fun notifyListener(network: Network?) {
        val l = listener ?: return
        if (network == null) {
            l.updateDefaultInterface("", -1, false, false)
            return
        }
        repeat(10) {
            val lp = connectivity.getLinkProperties(network)
            val name = lp?.interfaceName
            val index = name?.let { runCatching { NetworkInterface.getByName(it)?.index }.getOrNull() }
            if (name != null && index != null) {
                val caps = connectivity.getNetworkCapabilities(network)
                val metered = caps?.hasCapability(NetworkCapabilities.NET_CAPABILITY_NOT_METERED) == false
                l.updateDefaultInterface(name, index, metered, false)
                return
            }
            Thread.sleep(100)
        }
    }
}
