package dev.aurora.aurora_vpn.vpn

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.VpnService
import android.os.Bundle
import android.util.Log
import dev.aurora.aurora_vpn.MainActivity

/**
 * Invisible activity behind the quick settings tile and the home-screen
 * widget. Connects without showing the app: it only brings up the system
 * VPN consent dialog when Android asks for it again (e.g. after another VPN
 * app was used), starts the tunnel from the foreground — which Android 14+
 * requires for foreground services — and finishes right away.
 */
class VpnToggleActivity : Activity() {

    companion object {
        private const val REQUEST_CONSENT = 0x7101

        fun intent(context: Context): Intent =
            Intent(context, VpnToggleActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_NO_ANIMATION)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (savedInstanceState != null) return // Recreated while the consent dialog is up.
        when (VpnHub.status) {
            VpnStatus.STARTED, VpnStatus.STARTING -> {
                AuroraVpnService.stop(this)
                done()
            }
            VpnStatus.STOPPING -> done()
            VpnStatus.STOPPED -> connect()
        }
    }

    private fun connect() {
        if (VpnHub.loadConfig(this) == null) {
            // No server has ever been picked: that needs the app.
            startActivity(Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
            done()
            return
        }
        val consent = VpnService.prepare(this)
        if (consent == null) {
            start()
        } else {
            @Suppress("DEPRECATION")
            startActivityForResult(consent, REQUEST_CONSENT)
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != REQUEST_CONSENT) return
        if (resultCode == RESULT_OK) start() else done()
    }

    private fun start() {
        runCatching { AuroraVpnService.start(this) }
            .onFailure { Log.w("AuroraToggle", "start", it) }
        done()
    }

    private fun done() {
        finish()
        @Suppress("DEPRECATION")
        overridePendingTransition(0, 0)
    }
}
