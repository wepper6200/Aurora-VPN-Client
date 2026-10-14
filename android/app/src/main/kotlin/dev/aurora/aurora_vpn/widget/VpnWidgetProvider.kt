package dev.aurora.aurora_vpn.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.widget.RemoteViews
import dev.aurora.aurora_vpn.MainActivity
import dev.aurora.aurora_vpn.R
import dev.aurora.aurora_vpn.vpn.AuroraVpnService
import dev.aurora.aurora_vpn.vpn.VpnHub
import dev.aurora.aurora_vpn.vpn.VpnStatus
import dev.aurora.aurora_vpn.vpn.VpnSurfaces

/**
 * Home-screen widget: a translucent capsule with a power button, the status
 * and the selected server. Re-rendered on every status change, so each
 * button's PendingIntent always matches what a tap should do now.
 */
class VpnWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        manager.updateAppWidget(ids, render(context))
    }

    companion object {
        private const val TEAL = 0xFF2DE2C5.toInt()
        private const val ON_TEAL = 0xFF04201B.toInt()
        private const val WHITE = 0xFFFFFFFF.toInt()
        private const val WHITE_MUTED = 0xB3FFFFFF.toInt()

        fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context) ?: return
            val ids = manager.getAppWidgetIds(ComponentName(context, VpnWidgetProvider::class.java))
            if (ids.isNotEmpty()) manager.updateAppWidget(ids, render(context))
        }

        private fun render(context: Context): RemoteViews {
            val status = VpnHub.status
            val views = RemoteViews(context.packageName, R.layout.widget_vpn)
            val flags = PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            val openApp = PendingIntent.getActivity(
                context,
                20,
                Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                flags,
            )

            val (button, icon) = when (status) {
                VpnStatus.STARTED -> R.drawable.widget_btn_on to ON_TEAL
                VpnStatus.STARTING, VpnStatus.STOPPING -> R.drawable.widget_btn_busy to WHITE
                VpnStatus.STOPPED -> R.drawable.widget_btn_off to WHITE
            }
            views.setInt(R.id.widget_toggle, "setBackgroundResource", button)
            views.setInt(R.id.widget_power, "setColorFilter", icon)
            views.setTextViewText(R.id.widget_status, VpnSurfaces.statusText(context))
            views.setTextColor(R.id.widget_status, if (status == VpnStatus.STARTED) TEAL else WHITE)

            val server = VpnHub.loadLabel(context)
            views.setTextViewText(
                R.id.widget_server,
                when {
                    server.isNotEmpty() -> server
                    else -> context.getString(R.string.widget_hint_setup)
                },
            )
            views.setTextColor(R.id.widget_server, WHITE_MUTED)

            val toggle: PendingIntent = when (status) {
                VpnStatus.STARTED, VpnStatus.STARTING -> PendingIntent.getService(
                    context,
                    21,
                    Intent(context, AuroraVpnService::class.java).setAction(AuroraVpnService.ACTION_STOP),
                    flags,
                )
                VpnStatus.STOPPING -> openApp
                VpnStatus.STOPPED -> if (VpnSurfaces.canStartSilently(context)) {
                    val start = Intent(context, AuroraVpnService::class.java)
                        .setAction(AuroraVpnService.ACTION_START)
                    if (Build.VERSION.SDK_INT >= 26) {
                        PendingIntent.getForegroundService(context, 22, start, flags)
                    } else {
                        PendingIntent.getService(context, 22, start, flags)
                    }
                } else {
                    openApp
                }
            }
            views.setOnClickPendingIntent(R.id.widget_toggle, toggle)
            views.setOnClickPendingIntent(R.id.widget_root, openApp)
            return views
        }
    }
}
