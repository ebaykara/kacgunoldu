package com.emalabs.kacgunoldu.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.graphics.Bitmap
import android.os.Build
import android.os.Bundle
import android.util.SizeF
import android.view.View
import android.widget.RemoteViews
import com.emalabs.kacgunoldu.R
import com.emalabs.kacgunoldu.widget.WidgetViews.tint

/**
 * "Kartlar": the most urgent cards as rows — the app's list layout — under
 * the `Kaç gün oldu?` title and, only when something is overdue, the
 * `{n} kart gecikti` badge. As many rows as the widget's height holds.
 * A row opens its card; the title opens the app.
 */
class CardListWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        update(context, manager, ids)
    }

    override fun onAppWidgetOptionsChanged(context: Context, manager: AppWidgetManager, id: Int, options: Bundle) {
        update(context, manager, intArrayOf(id))
    }

    companion object {
        fun update(context: Context, manager: AppWidgetManager, ids: IntArray) {
            if (ids.isEmpty()) return
            val snapshot = WidgetSnapshot.load(context)
            // Rings are drawn once per card and shared by every size's layout.
            val rings = HashMap<String, Bitmap>()
            for (id in ids) manager.updateAppWidget(id, views(context, manager, id, snapshot, rings))
            WidgetViews.scheduleMidnight(context)
        }

        private fun views(
            context: Context,
            manager: AppWidgetManager,
            id: Int,
            snapshot: WidgetSnapshot?,
            rings: HashMap<String, Bitmap>,
        ): RemoteViews {
            val options = manager.getAppWidgetOptions(id)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val sizes = options.getParcelableArrayList<SizeF>(AppWidgetManager.OPTION_APPWIDGET_SIZES)
                if (!sizes.isNullOrEmpty()) {
                    return RemoteViews(sizes.associateWith { build(context, snapshot, it.height, rings) })
                }
            }
            val height = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 180).toFloat()
            return build(context, snapshot, height, rings)
        }

        /** Rows that fit under the header: padding + header ≈ 66dp, a row 62dp. */
        private fun rowsFor(heightDp: Float) = ((heightDp - 66f) / 62f).toInt().coerceIn(1, 8)

        private fun build(
            context: Context,
            snapshot: WidgetSnapshot?,
            heightDp: Float,
            rings: HashMap<String, Bitmap>,
        ): RemoteViews {
            val theme = snapshot?.theme ?: ThemeColors.DEFAULT
            val strings = snapshot?.strings ?: WidgetStrings.DEFAULT
            val v = RemoteViews(context.packageName, R.layout.widget_list)
            v.tint(R.id.bg, theme.surface)
            v.setTextViewText(R.id.title, strings.title)
            v.setTextColor(R.id.title, theme.onSurface)
            v.setOnClickPendingIntent(R.id.header, WidgetViews.openApp(context, null))

            val late = snapshot?.lateCount ?: 0
            v.setViewVisibility(R.id.badge, if (late > 0) View.VISIBLE else View.GONE)
            if (late > 0) {
                v.tint(R.id.badge_bg, theme.primary)
                v.setTextViewText(R.id.badge_text, strings.late(late))
                v.setTextColor(R.id.badge_text, theme.onPrimary)
            }

            v.removeAllViews(R.id.rows)
            val cards = snapshot?.ordered.orEmpty()
            if (cards.isEmpty()) {
                v.setViewVisibility(R.id.rows, View.GONE)
                v.setViewVisibility(R.id.empty, View.VISIBLE)
                v.setTextViewText(R.id.empty_text, if (snapshot == null) strings.openApp else strings.firstCard)
                v.setTextColor(R.id.empty_text, theme.muted)
                v.setInt(R.id.empty_glyph, "setColorFilter", theme.primary)
                v.setOnClickPendingIntent(R.id.empty, WidgetViews.openApp(context, null))
                return v
            }
            v.setViewVisibility(R.id.rows, View.VISIBLE)
            v.setViewVisibility(R.id.empty, View.GONE)
            for (card in cards.take(rowsFor(heightDp))) v.addView(R.id.rows, row(context, snapshot!!, card, rings))
            return v
        }

        private fun row(context: Context, snapshot: WidgetSnapshot, card: WidgetCard, rings: HashMap<String, Bitmap>): RemoteViews {
            val colors = snapshot.colors(card)
            val r = RemoteViews(context.packageName, R.layout.widget_list_row)
            r.tint(R.id.row_bg, colors.bg)
            r.setImageViewBitmap(
                R.id.row_ring,
                rings.getOrPut(card.id) { WidgetViews.ring(context, RING_DP, card.pct, colors.ring, colors.track) },
            )
            r.setImageViewResource(R.id.row_glyph, WidgetViews.glyph(context, card.icon))
            r.setInt(R.id.row_glyph, "setColorFilter", colors.ink)
            r.setTextViewText(R.id.row_name, card.name)
            r.setTextColor(R.id.row_name, colors.ink)
            WidgetViews.status(r, R.id.row_status, R.id.row_status_bold, card, colors)
            WidgetViews.doneButton(context, r, snapshot, card, colors, R.id.row_done, R.id.row_done_bg, R.id.row_done_icon)
            r.setTextViewText(R.id.row_days, card.dayText)
            r.setTextColor(R.id.row_days, colors.ink)
            r.setTextViewText(R.id.row_unit, card.unitText)
            r.setTextColor(R.id.row_unit, WidgetViews.withAlpha(colors.ink, 0.6f))
            r.setContentDescription(R.id.row_root, "${card.name}, ${card.dayText} ${card.unitText}, ${card.status}")
            r.setOnClickPendingIntent(R.id.row_root, WidgetViews.openApp(context, card.id))
            return r
        }

        private const val RING_DP = 36
    }
}
