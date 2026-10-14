package dev.aurora.aurora_vpn.vpn

import android.content.ComponentName
import android.content.Context
import android.net.VpnService
import android.service.quicksettings.TileService
import android.util.Log
import dev.aurora.aurora_vpn.R
import dev.aurora.aurora_vpn.widget.VpnWidgetProvider

/**
 * System entry points outside the app UI: the quick settings tile and the
 * home-screen widget. Both start the tunnel from the request the app saved
 * (see [VpnHub.saveRequest]), exactly like Always-on VPN does.
 */
object VpnSurfaces {
    private const val TAG = "AuroraSurfaces"

    /**
     * Whether a tap can connect right away: the VPN consent was given and a
     * server config is saved. Otherwise the app has to be opened.
     */
    fun canStartSilently(context: Context): Boolean =
        VpnService.prepare(context) == null && VpnHub.loadConfig(context) != null

    /** Status line shown by the tile and the widget. */
    fun statusText(context: Context): String = context.getString(
        when (VpnHub.status) {
            VpnStatus.STARTED -> R.string.notification_connected
            VpnStatus.STARTING -> R.string.notification_connecting
            VpnStatus.STOPPING -> R.string.status_disconnecting
            VpnStatus.STOPPED -> R.string.status_disconnected
        },
    )

    /** Re-renders the tile and every widget after a status or server change. */
    fun refresh(context: Context) {
        runCatching {
            TileService.requestListeningState(context, ComponentName(context, VpnTileService::class.java))
        }.onFailure { Log.w(TAG, "tile refresh", it) }
        runCatching { VpnWidgetProvider.updateAll(context) }
            .onFailure { Log.w(TAG, "widget refresh", it) }
    }
}
