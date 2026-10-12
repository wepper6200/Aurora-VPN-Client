package dev.aurora.aurora_vpn

import android.content.Context
import android.os.Build
import dev.aurora.aurora_vpn.vpn.AuroraVpnService
import java.io.File
import java.io.PrintWriter
import java.io.StringWriter
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Keeps the last crash so it can be shown in the app's Logs tab after a
 * restart — no adb needed. Two sources:
 * - uncaught JVM exceptions (written by [install]);
 * - Go panics in the core, which libbox writes to `files/core/CrashReport-*.log`
 *   and archives into `files/core/crash_reports/` on the next start.
 * Nothing leaves the device unless the user copies it.
 */
object CrashLog {
    private const val MAX_CHARS = 16_000

    private fun javaFile(context: Context) = File(context.filesDir, "crash-java.txt")

    fun install(context: Context) {
        val app = context.applicationContext
        val previous = Thread.getDefaultUncaughtExceptionHandler()
        Thread.setDefaultUncaughtExceptionHandler { thread, error ->
            runCatching {
                val trace = StringWriter().also { error.printStackTrace(PrintWriter(it)) }
                val stamp = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.US).format(Date())
                javaFile(app).writeText(
                    "$stamp  ${Build.MANUFACTURER} ${Build.MODEL}, Android ${Build.VERSION.RELEASE}\n" +
                        "thread: ${thread.name}\n$trace",
                )
            }
            previous?.uncaughtException(thread, error)
        }
    }

    /** Returns and deletes the newest crash report, or null. */
    fun takeLast(context: Context): String? {
        val core = File(context.filesDir, "core")
        val candidates = buildList {
            javaFile(context).takeIf { it.isFile && it.length() > 0 }?.let(::add)
            core.listFiles { f -> f.name.startsWith("CrashReport") && f.length() > 0 }?.let(::addAll)
            File(core, "crash_reports").listFiles()?.filter { it.isFile && it.length() > 0 }?.let(::addAll)
        }
        val newest = candidates.maxByOrNull { it.lastModified() } ?: return null
        val text = runCatching { newest.readText() }.getOrNull()
        // The live CrashReport file belongs to the core only after it started in this process.
        val coreRunning = AuroraVpnService.libboxReady
        candidates.filter { coreRunning.not() || it.parentFile?.name == "crash_reports" || it == javaFile(context) }
            .forEach { runCatching { it.delete() } }
        return text?.takeLast(MAX_CHARS)?.takeIf { it.isNotBlank() }
    }
}
