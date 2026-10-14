package dev.aurora.aurora_vpn.vpn

import android.content.Context
import android.os.Handler
import android.os.Looper
import java.io.File
import java.util.concurrent.CopyOnWriteArraySet

enum class VpnStatus(val wire: String) {
    STOPPED("disconnected"),
    STARTING("connecting"),
    STARTED("connected"),
    STOPPING("disconnecting"),
}

/** Events forwarded to Flutter. Listeners are called on the main thread. */
sealed interface VpnEvent {
    data class Status(val status: VpnStatus, val error: String?, val startedAt: Long?) : VpnEvent
    data class Traffic(val up: Long, val down: Long, val upTotal: Long, val downTotal: Long) : VpnEvent
    data class Log(val level: Int, val message: String) : VpnEvent
}

/**
 * Process-wide tunnel state shared by [AuroraVpnService] and the Flutter
 * bridge. The service runs in the app process, so a singleton is enough.
 */
object VpnHub {
    private val main = Handler(Looper.getMainLooper())
    private val listeners = CopyOnWriteArraySet<(VpnEvent) -> Unit>()

    @Volatile var status: VpnStatus = VpnStatus.STOPPED
        private set
    @Volatile var lastError: String? = null
        private set
    @Volatile var startedAt: Long? = null
        private set

    /** Application context, for refreshing the tile and widgets. */
    @Volatile private var appContext: Context? = null

    fun init(context: Context) {
        appContext = context.applicationContext
    }

    fun addListener(l: (VpnEvent) -> Unit) {
        listeners += l
    }

    fun removeListener(l: (VpnEvent) -> Unit) {
        listeners -= l
    }

    fun setStatus(status: VpnStatus, error: String? = null) {
        this.status = status
        lastError = error
        startedAt = if (status == VpnStatus.STARTED) System.currentTimeMillis() else null
        emit(VpnEvent.Status(status, error, startedAt))
        appContext?.let { VpnSurfaces.refresh(it) }
    }

    fun emit(event: VpnEvent) {
        if (listeners.isEmpty()) return
        main.post { listeners.forEach { it(event) } }
    }

    // --- persisted request --------------------------------------------------

    private fun configFile(context: Context) = File(context.filesDir, "active-config.json")
    private fun labelFile(context: Context) = File(context.filesDir, "active-label.txt")
    private fun xrayFile(context: Context) = File(context.filesDir, "active-xray.json")

    /** Stores the config so Always-on VPN, the tile and widgets can start without the UI. */
    fun saveRequest(context: Context, config: String, label: String, xray: String?) {
        configFile(context).writeText(config)
        labelFile(context).writeText(label)
        if (xray.isNullOrBlank()) xrayFile(context).delete() else xrayFile(context).writeText(xray)
        VpnSurfaces.refresh(context)
    }

    /** Xray-core config for servers that need it; null for sing-box-only servers. */
    fun loadXray(context: Context): String? =
        xrayFile(context).takeIf { it.exists() }?.readText()?.takeIf { it.isNotBlank() }

    fun loadConfig(context: Context): String? =
        configFile(context).takeIf { it.exists() }?.readText()?.takeIf { it.isNotBlank() }

    fun loadLabel(context: Context): String =
        labelFile(context).takeIf { it.exists() }?.readText().orEmpty()
}
