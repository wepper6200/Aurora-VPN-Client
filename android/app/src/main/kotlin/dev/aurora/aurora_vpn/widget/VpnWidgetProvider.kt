package dev.aurora.aurora_vpn.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.widget.RemoteViews
import dev.aurora.aurora_vpn.R
import dev.aurora.aurora_vpn.vpn.VpnHub
import dev.aurora.aurora_vpn.vpn.VpnStatus
import dev.aurora.aurora_vpn.vpn.VpnSurfaces
import dev.aurora.aurora_vpn.vpn.VpnToggleActivity

/**
 * Home-screen widget: a translucent capsule with a power button, the status
 * and the selected server. A tap anywhere toggles the VPN without opening the
 * app; it re-renders on every status change.
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

            // The whole widget toggles, like the tile. The invisible toggle
            // activity connects from the foreground (OEM ROMs and Android 14+
            // refuse background starts), shows only the system consent dialog
            // when needed, and opens the app only if no server was ever picked.
            val toggle = PendingIntent.getActivity(context, 23, VpnToggleActivity.intent(context), flags)
            views.setOnClickPendingIntent(R.id.widget_toggle, toggle)
            views.setOnClickPendingIntent(R.id.widget_root, toggle)
            return views
        }
    }
}
