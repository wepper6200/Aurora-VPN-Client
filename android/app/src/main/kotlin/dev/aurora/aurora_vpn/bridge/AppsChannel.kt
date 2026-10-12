package dev.aurora.aurora_vpn.bridge

import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors

/**
 * `aurora/apps`: installed apps for per-app split tunneling.
 * Package manager calls are slow, so they run off the main thread.
 */
class AppsChannel(private val context: Context, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, "aurora/apps")
    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    init {
        channel.setMethodCallHandler(this)
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        io.shutdown()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "list" -> io.execute {
                val out = runCatching { list(call.argument<Boolean>("includeSystem") == true) }
                main.post { out.fold(result::success) { result.error("LIST", it.message, null) } }
            }
            "icon" -> io.execute {
                val out = runCatching { icon(call.argument<String>("package")!!, call.argument<Int>("size") ?: 96) }
                main.post { out.fold(result::success) { result.error("ICON", it.message, null) } }
            }
            else -> result.notImplemented()
        }
    }

    private fun list(includeSystem: Boolean): List<Map<String, Any>> {
        val pm = context.packageManager
        val self = context.packageName
        return pm.getInstalledApplications(PackageManager.GET_META_DATA)
            .asSequence()
            .filter { it.packageName != self }
            // Apps without internet access can't be routed anyway.
            .filter { pm.checkPermission(android.Manifest.permission.INTERNET, it.packageName) == PackageManager.PERMISSION_GRANTED }
            .map {
                val system = it.flags and ApplicationInfo.FLAG_SYSTEM != 0 &&
                    it.flags and ApplicationInfo.FLAG_UPDATED_SYSTEM_APP == 0
                Triple(it, system, pm.getApplicationLabel(it).toString())
            }
            .filter { includeSystem || !it.second }
            .map { (info, system, label) ->
                mapOf("package" to info.packageName, "label" to label, "system" to system)
            }
            .toList()
    }

    private fun icon(pkg: String, size: Int): ByteArray {
        val drawable = context.packageManager.getApplicationIcon(pkg)
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        drawable.setBounds(0, 0, size, size)
        drawable.draw(Canvas(bitmap))
        return ByteArrayOutputStream().use {
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, it)
            bitmap.recycle()
            it.toByteArray()
        }
    }
}
