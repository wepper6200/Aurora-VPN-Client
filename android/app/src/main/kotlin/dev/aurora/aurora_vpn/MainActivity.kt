package dev.aurora.aurora_vpn

import android.content.Intent
import dev.aurora.aurora_vpn.bridge.AppsChannel
import dev.aurora.aurora_vpn.bridge.VpnChannel
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var vpn: VpnChannel? = null
    private var apps: AppsChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        vpn = VpnChannel(this, messenger)
        apps = AppsChannel(applicationContext, messenger)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        vpn?.dispose()
        apps?.dispose()
        vpn = null
        apps = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (vpn?.onActivityResult(requestCode, resultCode) == true) return
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
    }
}
