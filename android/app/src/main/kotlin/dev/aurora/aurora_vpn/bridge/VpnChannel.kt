package dev.aurora.aurora_vpn.bridge

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.net.VpnService
import android.os.Build
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import dev.aurora.aurora_vpn.vpn.AuroraVpnService
import dev.aurora.aurora_vpn.vpn.VpnEvent
import dev.aurora.aurora_vpn.vpn.VpnHub
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * `aurora/vpn` (methods) and `aurora/vpn/events` (status, traffic, logs).
 * Wire format mirrors `lib/data/vpn/android_vpn_controller.dart`.
 */
class VpnChannel(private val activity: Activity, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    companion object {
        const val REQUEST_VPN = 0x7001
        const val REQUEST_NOTIFICATIONS = 0x7002
    }

    private val methods = MethodChannel(messenger, "aurora/vpn")
    private val events = EventChannel(messenger, "aurora/vpn/events")
    private var sink: EventChannel.EventSink? = null
    private var pendingPermission: MethodChannel.Result? = null

    private val listener: (VpnEvent) -> Unit = { event -> sink?.success(event.toWire()) }

    init {
        methods.setMethodCallHandler(this)
        events.setStreamHandler(this)
    }

    fun dispose() {
        methods.setMethodCallHandler(null)
        events.setStreamHandler(null)
        VpnHub.removeListener(listener)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "prepare" -> prepare(result)
            "start" -> {
                val config = call.argument<String>("config")
                if (config.isNullOrBlank()) {
                    result.error("ARGS", "config is required", null)
                    return
                }
                VpnHub.saveRequest(
                    activity,
                    config,
                    call.argument<String>("label").orEmpty(),
                    call.argument<String>("xray"),
                )
                AuroraVpnService.start(activity)
                result.success(null)
            }
            "stop" -> {
                AuroraVpnService.stop(activity)
                result.success(null)
            }
            "state" -> result.success(statusMap())
            "openVpnSettings" -> {
                activity.startActivity(Intent(Settings.ACTION_VPN_SETTINGS))
                result.success(null)
            }
            "sdkInt" -> result.success(Build.VERSION.SDK_INT)
            "deviceInfo" -> result.success(
                mapOf(
                    "model" to "${Build.MANUFACTURER} ${Build.MODEL}".trim(),
                    "osVersion" to Build.VERSION.RELEASE,
                ),
            )
            else -> result.notImplemented()
        }
    }

    /** Asks for the VPN consent dialog if needed; resolves to whether we may start. */
    private fun prepare(result: MethodChannel.Result) {
        // Android 13+: without this the status notification (speed, Disconnect) is hidden.
        if (Build.VERSION.SDK_INT >= 33 &&
            ContextCompat.checkSelfPermission(activity, Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            ActivityCompat.requestPermissions(activity, arrayOf(Manifest.permission.POST_NOTIFICATIONS), REQUEST_NOTIFICATIONS)
        }
        val intent = VpnService.prepare(activity)
        if (intent == null) {
            result.success(true)
            return
        }
        pendingPermission?.success(false)
        pendingPermission = result
        activity.startActivityForResult(intent, REQUEST_VPN)
    }

    /** Forwarded from MainActivity.onActivityResult. */
    fun onActivityResult(requestCode: Int, resultCode: Int): Boolean {
        if (requestCode != REQUEST_VPN) return false
        pendingPermission?.success(resultCode == Activity.RESULT_OK)
        pendingPermission = null
        return true
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        sink = events
        VpnHub.addListener(listener)
        events.success(statusMap())
    }

    override fun onCancel(arguments: Any?) {
        VpnHub.removeListener(listener)
        sink = null
    }

    private fun statusMap(): Map<String, Any?> = VpnEvent.Status(
        VpnHub.status,
        VpnHub.lastError,
        VpnHub.startedAt,
    ).toWire()

    private fun VpnEvent.toWire(): Map<String, Any?> = when (this) {
        is VpnEvent.Status -> mapOf(
            "type" to "status",
            "status" to status.wire,
            "error" to error,
            "startedAt" to startedAt,
        )
        is VpnEvent.Traffic -> mapOf(
            "type" to "traffic",
            "up" to up,
            "down" to down,
            "upTotal" to upTotal,
            "downTotal" to downTotal,
        )
        is VpnEvent.Log -> mapOf("type" to "log", "level" to level, "message" to message)
    }
}
