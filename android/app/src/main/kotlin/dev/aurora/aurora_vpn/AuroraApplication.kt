package dev.aurora.aurora_vpn

import dev.aurora.aurora_vpn.vpn.VpnHub
import io.flutter.app.FlutterApplication

class AuroraApplication : FlutterApplication() {
    override fun onCreate() {
        super.onCreate()
        CrashLog.install(this)
        VpnHub.init(this)
    }
}
