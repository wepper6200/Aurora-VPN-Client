package dev.aurora.aurora_vpn

import io.flutter.app.FlutterApplication

class AuroraApplication : FlutterApplication() {
    override fun onCreate() {
        super.onCreate()
        CrashLog.install(this)
    }
}
