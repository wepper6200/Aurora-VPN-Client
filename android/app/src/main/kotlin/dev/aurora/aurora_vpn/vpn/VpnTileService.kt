package dev.aurora.aurora_vpn.vpn

import android.annotation.SuppressLint
import android.app.PendingIntent
import android.content.Intent
import android.graphics.drawable.Icon
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import android.util.Log
import dev.aurora.aurora_vpn.R

/**
 * Quick settings tile: one tap connects to the selected server or
 * disconnects, without opening the app. Only the system VPN consent dialog
 * may appear (when Android asks again); the app opens only if no server has
 * ever been picked.
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
            VpnStatus.STOPPED -> connect()
        }
        render()
    }

    private fun connect() {
        // Fast path: consent is in place, start right here with the shade open.
        if (VpnSurfaces.canStartSilently(this)) {
            val started = runCatching { AuroraVpnService.start(this) }
                .onFailure { Log.w("AuroraTile", "direct start refused", it) }
                .isSuccess
            if (started) return
        }
        // Consent dialog needed, or Android refused a background start: the
        // invisible toggle activity handles both without opening the app.
        launch(VpnToggleActivity.intent(this))
    }

    @SuppressLint("StartActivityAndCollapseDeprecated")
    private fun launch(intent: Intent) {
        val run = Runnable {
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
        if (isLocked) unlockAndRun(run) else run.run()
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
