package com.emalabs.kacgunoldu.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.util.SizeF
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import com.emalabs.kacgunoldu.R
import com.emalabs.kacgunoldu.widget.WidgetViews.tint

/**
 * "Kart": one card, drawn like its tile in the app — ring and glyph, name,
 * the day count and one status line, in the card's tier colours.
 *
 * Shows the card picked in [CardWidgetConfigActivity], or, until one is
 * picked (or once it is deleted), whichever card is most overdue.
 */
class CardWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        update(context, manager, ids)
    }

    override fun onAppWidgetOptionsChanged(context: Context, manager: AppWidgetManager, id: Int, options: Bundle) {
        update(context, manager, intArrayOf(id))
    }

    override fun onDeleted(context: Context, ids: IntArray) {
        ids.forEach { CardWidgetConfigActivity.forget(context, it) }
    }

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            // Midnight, or the clock / time zone changed: every day count moves.
            WidgetViews.ACTION_REFRESH,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_DATE_CHANGED -> WidgetViews.refreshAll(context)
            // "Bugün yaptım" on any widget (both kinds send it here).
            WidgetViews.ACTION_DONE -> {
                val id = intent.getStringExtra(WidgetViews.EXTRA_CARD) ?: return
                val card = WidgetSnapshot.load(context)?.byId(id) ?: return
                if (card.doneToday) return
                WidgetSnapshot.markDone(context, id)
                WidgetViews.refreshAll(context)
            }
            // Placed from the app's "Ana ekrana ekle" (either kind): the
            // single card shows the card it was asked for; the app hears of it.
            WidgetViews.ACTION_PINNED -> {
                val widgetId = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
                val cardId = intent.getStringExtra(WidgetViews.EXTRA_CARD)
                if (widgetId != AppWidgetManager.INVALID_APPWIDGET_ID && cardId != null) {
                    CardWidgetConfigActivity.remember(context, widgetId, cardId)
                    update(context, AppWidgetManager.getInstance(context), intArrayOf(widgetId))
                }
                WidgetViews.onPinned?.invoke()
            }
            else -> super.onReceive(context, intent)
        }
    }

    companion object {
        fun update(context: Context, manager: AppWidgetManager, ids: IntArray) {
            if (ids.isEmpty()) return
            val snapshot = WidgetSnapshot.load(context)
            for (id in ids) {
                val card = snapshot?.let { it.byId(CardWidgetConfigActivity.pickedCard(context, id)) ?: it.ordered.firstOrNull() }
                manager.updateAppWidget(id, views(context, manager, id, snapshot, card))
            }
            WidgetViews.scheduleMidnight(context)
        }

        private fun views(
            context: Context,
            manager: AppWidgetManager,
            id: Int,
            snapshot: WidgetSnapshot?,
            card: WidgetCard?,
        ): RemoteViews {
            val options = manager.getAppWidgetOptions(id)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val sizes = options.getParcelableArrayList<SizeF>(AppWidgetManager.OPTION_APPWIDGET_SIZES)
                if (!sizes.isNullOrEmpty()) {
                    // One layout per size the launcher may show; the ring is drawn once.
                    val ring = card?.let { ringFor(context, snapshot!!, it) }
                    return RemoteViews(sizes.associateWith { build(context, snapshot, card, it.height, ring) })
                }
            }
            // Portrait: the launcher's max height is the one on screen.
            val height = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 170).toFloat()
            return build(context, snapshot, card, height, card?.let { ringFor(context, snapshot!!, it) })
        }

        private fun ringFor(context: Context, snapshot: WidgetSnapshot, card: WidgetCard) =
            snapshot.colors(card).let { WidgetViews.ring(context, RING_DP, card.pct, it.ring, it.track) }

        private fun build(
            context: Context,
            snapshot: WidgetSnapshot?,
            card: WidgetCard?,
            heightDp: Float,
            ring: android.graphics.Bitmap?,
        ): RemoteViews {
            val v = RemoteViews(context.packageName, R.layout.widget_card)
            if (snapshot == null || card == null) {
                val theme = snapshot?.theme ?: ThemeColors.DEFAULT
                v.tint(R.id.bg, theme.surface)
                v.setViewVisibility(R.id.content, View.GONE)
                v.setViewVisibility(R.id.empty, View.VISIBLE)
                v.setTextViewText(
                    R.id.empty_text,
                    context.getString(if (snapshot == null) R.string.widget_open_app else R.string.widget_first_card),
                )
                v.setTextColor(R.id.empty_text, theme.onSurface)
                v.setInt(R.id.empty_glyph, "setColorFilter", theme.primary)
                v.setOnClickPendingIntent(R.id.widget_root, WidgetViews.openApp(context, null))
                return v
            }

            val colors = snapshot.colors(card)
            v.tint(R.id.bg, colors.bg)
            v.setImageViewBitmap(R.id.ring, ring)
            v.setImageViewResource(R.id.glyph, WidgetViews.glyph(context, card.icon))
            v.setInt(R.id.glyph, "setColorFilter", colors.ink)

            v.setTextViewText(R.id.name, card.name)
            v.setTextColor(R.id.name, colors.ink)
            v.setTextViewText(R.id.days, card.dayText)
            v.setTextColor(R.id.days, colors.ink)
            v.setTextViewText(R.id.unit, card.unitText)
            v.setTextColor(R.id.unit, WidgetViews.withAlpha(colors.ink, 0.72f))
            WidgetViews.status(v, R.id.status, R.id.status_bold, card, colors)
            WidgetViews.doneButton(context, v, snapshot, card, colors, R.id.done, R.id.done_bg, R.id.done_icon)

            // A short widget (the usual 2×2) gets a one-line name and a
            // smaller number, so nothing is cut off at the bottom edge.
            val compact = heightDp < 180f
            v.setInt(R.id.name, "setMaxLines", if (compact) 1 else 2)
            v.setTextViewTextSize(R.id.days, TypedValue.COMPLEX_UNIT_SP, if (compact) 44f else 54f)

            v.setContentDescription(
                R.id.widget_root,
                "${card.name}, ${card.dayText} ${card.unitText}, ${card.status}",
            )
            v.setOnClickPendingIntent(R.id.widget_root, WidgetViews.openApp(context, card.id))
            return v
        }

        private const val RING_DP = 40
    }
}
