package com.emalabs.kacgunoldu.widget

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.res.ColorStateList
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Bundle
import android.view.View
import android.view.ViewGroup
import android.view.WindowInsetsController
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import com.emalabs.kacgunoldu.R

/**
 * "Hangi kart?" — picks the card a [CardWidget] shows. Opens when the widget
 * is placed, and again on long-press → reconfigure where the launcher offers
 * it. The first choice keeps the automatic behaviour: always the most urgent
 * card. A widget placed from the app's "Ana ekrana ekle" arrives with its
 * card already chosen (WidgetViews.pin → ACTION_PINNED).
 */
class CardWidgetConfigActivity : Activity() {
    private var widgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Backing out leaves the widget unplaced (or unchanged).
        setResult(RESULT_CANCELED)
        widgetId = intent?.extras?.getInt(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
            ?: AppWidgetManager.INVALID_APPWIDGET_ID
        if (widgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        setContentView(R.layout.widget_config)
        val snapshot = WidgetSnapshot.load(this)
        val theme = snapshot?.theme ?: ThemeColors.DEFAULT
        val root = findViewById<View>(R.id.config_root)
        root.setBackgroundColor(theme.surface)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R && !theme.dark) {
            // Dark bar icons on a light theme.
            val dark = WindowInsetsController.APPEARANCE_LIGHT_STATUS_BARS or
                WindowInsetsController.APPEARANCE_LIGHT_NAVIGATION_BARS
            window.insetsController?.setSystemBarsAppearance(dark, dark)
        }
        findViewById<TextView>(R.id.config_title).setTextColor(theme.onSurface)
        findViewById<TextView>(R.id.config_hint).setTextColor(theme.muted)

        val list = findViewById<LinearLayout>(R.id.config_list)
        val current = pickedCard(this, widgetId)
        list.addView(
            option(
                list,
                title = getString(R.string.widget_config_auto),
                subtitle = getString(R.string.widget_config_auto_hint),
                glyph = R.drawable.wg_spark,
                ring = null,
                colors = TierColors(theme.surface, theme.onSurface, theme.primary, WidgetViews.withAlpha(theme.onSurface, 0.1f)),
                theme = theme,
                selected = current == null,
            ) { choose(null) },
        )
        for (card in snapshot?.ordered.orEmpty()) {
            val colors = snapshot!!.colors(card)
            list.addView(
                option(
                    list,
                    title = card.name,
                    subtitle = "${card.dayText} ${card.unitText} · ${card.status}",
                    glyph = WidgetViews.glyph(this, card.icon),
                    ring = card.pct,
                    colors = colors,
                    theme = theme,
                    selected = current == card.id,
                ) { choose(card.id) },
            )
        }
    }

    private fun option(
        parent: ViewGroup,
        title: String,
        subtitle: String,
        glyph: Int,
        ring: Int?,
        colors: TierColors,
        theme: ThemeColors,
        selected: Boolean,
        onClick: () -> Unit,
    ): View {
        val row = layoutInflater.inflate(R.layout.widget_config_row, parent, false)
        val density = resources.displayMetrics.density
        row.background = GradientDrawable().apply {
            cornerRadius = 18 * density
            setColor(colors.bg)
            if (selected) setStroke((2 * density).toInt(), theme.primary)
            else setStroke((1 * density).toInt(), theme.outline)
        }
        row.findViewById<ImageView>(R.id.config_ring).setImageBitmap(
            WidgetViews.ring(this, 40, ring ?: 100, colors.ring, colors.track),
        )
        row.findViewById<ImageView>(R.id.config_glyph).apply {
            setImageResource(glyph)
            imageTintList = ColorStateList.valueOf(colors.ink)
        }
        row.findViewById<TextView>(R.id.config_name).apply {
            text = title
            setTextColor(colors.ink)
        }
        row.findViewById<TextView>(R.id.config_sub).apply {
            text = subtitle
            setTextColor(WidgetViews.withAlpha(colors.ink, 0.65f))
        }
        row.setOnClickListener { onClick() }
        return row
    }

    private fun choose(cardId: String?) {
        getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().apply {
            if (cardId == null) remove(key(widgetId)) else putString(key(widgetId), cardId)
        }.apply()
        val manager = AppWidgetManager.getInstance(this)
        CardWidget.update(this, manager, intArrayOf(widgetId))
        setResult(RESULT_OK, Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId))
        finish()
    }

    companion object {
        private const val PREFS = "kac_gun_oldu_widgets"
        private fun key(widgetId: Int) = "card.$widgetId"

        /** The card picked for this widget, or `null` for "the most urgent one". */
        fun pickedCard(context: Context, widgetId: Int): String? =
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(key(widgetId), null)

        fun remember(context: Context, widgetId: Int, cardId: String) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putString(key(widgetId), cardId).apply()
        }

        fun forget(context: Context, widgetId: Int) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().remove(key(widgetId)).apply()
        }
    }
}
