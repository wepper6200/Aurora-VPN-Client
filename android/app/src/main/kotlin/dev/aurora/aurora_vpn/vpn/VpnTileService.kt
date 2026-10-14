package dev.aurora.aurora_vpn.vpn

import android.annotation.SuppressLint
import android.app.PendingIntent
import android.content.Intent
import android.graphics.drawable.Icon
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import android.util.Log
import dev.aurora.aurora_vpn.MainActivity
import dev.aurora.aurora_vpn.R

/**
 * Quick settings tile: one tap connects to the selected server or
 * disconnects. Opens the app when it can't connect on its own (no server
 * yet, or the VPN consent dialog still has to be shown).
 */
class VpnTileService : TileService() {

    /**
     * Live updates while the shade is open. requestListeningState() is a
     * no-op for non-active tiles, so without this the tile kept whatever it
     * showed when the shade opened (e.g. "off" right after tapping it).
     */
    private val statusListener: (VpnEvent) -> Unit = { if (it is VpnEvent.Status) render() }

    override fun onStartListening() {
        super.onStartListening()
        VpnHub.addListener(statusListener)
        render()
    }

    override fun onStopListening() {
        VpnHub.removeListener(statusListener)
        super.onStopListening()
    }

    override fun onClick() {
        super.onClick()
        when (VpnHub.status) {
            VpnStatus.STARTED, VpnStatus.STARTING -> AuroraVpnService.stop(this)
            VpnStatus.STOPPING -> Unit
            VpnStatus.STOPPED ->
                if (VpnSurfaces.canStartSilently(this)) {
                    runCatching { AuroraVpnService.start(this) }.onFailure {
                        Log.w("AuroraTile", "start from tile", it)
                        openApp()
                    }
                } else {
                    openApp()
                }
        }
        render()
    }

    @SuppressLint("StartActivityAndCollapseDeprecated")
    private fun openApp() {
        val intent = Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        if (Build.VERSION.SDK_INT >= 34) {
            startActivityAndCollapse(
                PendingIntent.getActivity(
                    this,
                    0,
                    intent,
                    PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
                ),
            )
        } else {
            @Suppress("DEPRECATION")
            startActivityAndCollapse(intent)
        }
    }

    private fun render() {
        val tile = qsTile ?: return
        val status = VpnHub.status
        tile.state = if (status == VpnStatus.STOPPED) Tile.STATE_INACTIVE else Tile.STATE_ACTIVE
        tile.icon = Icon.createWithResource(this, R.drawable.ic_stat_vpn)
        tile.label = getString(R.string.tile_label)
        if (Build.VERSION.SDK_INT >= 29) {
            // On/off is carried by the tile state; the subtitle names the server,
            // and switches to "Connecting…" / "Disconnecting…" in between.
            val settled = status == VpnStatus.STARTED || status == VpnStatus.STOPPED
            val server = VpnHub.loadLabel(this)
            tile.subtitle = if (settled && server.isNotEmpty()) server else VpnSurfaces.statusText(this)
        }
        tile.updateTile()
    }
}
