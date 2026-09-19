package com.emalabs.kacgunoldu.widget

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import android.net.Uri
import android.os.Build
import android.widget.RemoteViews
import com.emalabs.kacgunoldu.R
import com.emalabs.kacgunoldu.SplashActivity
import java.time.LocalDate
import java.time.ZoneId

/** Drawing and wiring shared by both widgets. */
internal object WidgetViews {
    const val ACTION_REFRESH = "com.emalabs.kacgunoldu.widget.REFRESH"
    const val ACTION_DONE = "com.emalabs.kacgunoldu.widget.DONE"
    const val ACTION_PINNED = "com.emalabs.kacgunoldu.widget.PINNED"
    const val EXTRA_CARD = "cardId"

    /**
     * Told when a widget asked for from the app has been placed. MIUI adds
     * it without any dialog once its permission is on, so this is the only
     * sign the person gets that it worked (MainActivity passes it to Dart).
     */
    var onPinned: (() -> Unit)? = null

    /** Redraws every placed widget — after the app writes a new snapshot, and at midnight. */
    fun refreshAll(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        CardWidget.update(context, manager, manager.getAppWidgetIds(ComponentName(context, CardWidget::class.java)))
        CardListWidget.update(context, manager, manager.getAppWidgetIds(ComponentName(context, CardListWidget::class.java)))
    }

    /**
     * Day counts roll over at local midnight. A non-waking alarm: it fires
     * when the phone next wakes after midnight, which is exactly when someone
     * could look.
     */
    fun scheduleMidnight(context: Context) {
        val alarms = context.getSystemService(AlarmManager::class.java) ?: return
        val zone = ZoneId.systemDefault()
        val at = LocalDate.now(zone).plusDays(1).atStartOfDay(zone).toInstant().toEpochMilli() + 5_000
        val intent = Intent(context, CardWidget::class.java).setAction(ACTION_REFRESH)
        val pending = PendingIntent.getBroadcast(
            context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        alarms.set(AlarmManager.RTC, at, pending)
    }

    /**
     * Opens the app — on [cardId]'s detail page when given. Goes through
     * SplashActivity like any launch; the link reaches Flutter as a deep link
     * that CardStore turns into "open this card".
     */
    fun openApp(context: Context, cardId: String?): PendingIntent {
        val intent = Intent(context, SplashActivity::class.java).apply {
            if (cardId != null) {
                action = Intent.ACTION_VIEW
                data = Uri.parse("kacgunoldu://app/card/${Uri.encode(cardId)}")
            } else {
                // A plain launch, as from the app icon.
                action = Intent.ACTION_MAIN
                addCategory(Intent.CATEGORY_LAUNCHER)
            }
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        return PendingIntent.getActivity(
            context,
            cardId?.hashCode() ?: 0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    /**
     * The "Bugün yaptım" button: a soft circle with a check, or — once the
     * card is done today — a filled one, which does nothing more when tapped.
     */
    fun doneButton(
        context: Context,
        v: RemoteViews,
        snapshot: WidgetSnapshot,
        card: WidgetCard,
        colors: TierColors,
        buttonId: Int,
        bgId: Int,
        iconId: Int,
    ) {
        if (!snapshot.doneButton) {
            v.setViewVisibility(buttonId, android.view.View.GONE)
            return
        }
        v.setViewVisibility(buttonId, android.view.View.VISIBLE)
        v.tint(bgId, if (card.doneToday) colors.ring else withAlpha(colors.ink, 0.1f))
        v.setInt(iconId, "setColorFilter", if (card.doneToday) colors.bg else colors.ink)
        v.setContentDescription(buttonId, if (card.doneToday) "Bugün yapıldı" else "Bugün yaptım")
        val intent = Intent(context, CardWidget::class.java)
            .setAction(ACTION_DONE)
            .setData(Uri.parse("kacgunoldu://done/${Uri.encode(card.id)}"))
            .putExtra(EXTRA_CARD, card.id)
        v.setOnClickPendingIntent(
            buttonId,
            PendingIntent.getBroadcast(
                context, card.id.hashCode(), intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            ),
        )
    }

    /**
     * Asks the launcher to place a widget (Android 8+). For the single-card
     * one, [cardId] is remembered for it once placed (ACTION_PINNED).
     *
     * "requested", "blocked" (the phone drops the request without asking —
     * see [pinBlocked]) or "unsupported".
     */
    fun pin(context: Context, cardId: String?, list: Boolean): String {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return "unsupported"
        val manager = context.getSystemService(AppWidgetManager::class.java) ?: return "unsupported"
        if (!manager.isRequestPinAppWidgetSupported) return "unsupported"
        if (pinBlocked(context)) return "blocked"
        val provider = ComponentName(context, if (list) CardListWidget::class.java else CardWidget::class.java)
        // Mutable: the launcher adds the new widget's id to it.
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or
            (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) PendingIntent.FLAG_MUTABLE else 0)
        val callback = PendingIntent.getBroadcast(
            context,
            if (list) -1 else cardId.hashCode(),
            Intent(context, CardWidget::class.java).setAction(ACTION_PINNED)
                .putExtra(EXTRA_CARD, if (list) null else cardId),
            flags,
        )
        return if (manager.requestPinAppWidget(provider, null, callback)) "requested" else "unsupported"
    }

    /**
     * MIUI (Xiaomi, Redmi, POCO) asks its own "Ana ekran kısayolları"
     * permission before a widget can be added from the app — and once it is
     * refused, every later request is dropped silently, no dialog at all.
     * That permission is MIUI's app op 10017; only a refusal counts as
     * blocked (it starts out as "ask").
     */
    private fun pinBlocked(context: Context): Boolean {
        if (!Build.MANUFACTURER.equals("Xiaomi", ignoreCase = true)) return false
        return try {
            val ops = context.getSystemService(android.app.AppOpsManager::class.java) ?: return false
            val check = android.app.AppOpsManager::class.java.getMethod(
                "checkOpNoThrow", Int::class.javaPrimitiveType, Int::class.javaPrimitiveType, String::class.java,
            )
            val mode = check.invoke(ops, MIUI_OP_SHORTCUTS, android.os.Process.myUid(), context.packageName) as Int
            mode == android.app.AppOpsManager.MODE_IGNORED || mode == android.app.AppOpsManager.MODE_ERRORED
        } catch (_: Exception) {
            false
        }
    }

    /**
     * Where that permission can be turned back on: MIUI's own permission
     * page for the app, or the standard app info page elsewhere.
     */
    fun openPinPermission(activity: android.app.Activity) {
        val miui = Intent("miui.intent.action.APP_PERM_EDITOR")
            .setClassName("com.miui.securitycenter", "com.miui.permcenter.permissions.PermissionsEditorActivity")
            .putExtra("extra_pkgname", activity.packageName)
        val standard = Intent(android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
            .setData(Uri.parse("package:${activity.packageName}"))
        for (intent in listOf(miui, standard)) {
            try {
                activity.startActivity(intent)
                return
            } catch (_: Exception) {
            }
        }
    }

    private const val MIUI_OP_SHORTCUTS = 10017

    fun canPin(context: Context): Boolean =
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            context.getSystemService(AppWidgetManager::class.java)?.isRequestPinAppWidgetSupported == true

    /** The rhythm ring (lib/widgets/rhythm_ring.dart): a track and an arc from 12 o'clock. */
    fun ring(context: Context, sizeDp: Int, pct: Int, ring: Int, track: Int): Bitmap {
        val px = (sizeDp * context.resources.displayMetrics.density).toInt().coerceAtLeast(1)
        val bitmap = Bitmap.createBitmap(px, px, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        // Same proportion as the app: a 6-unit stroke on a 52-unit ring.
        val stroke = px * 6f / 52f
        val rect = RectF(stroke / 2, stroke / 2, px - stroke / 2, px - stroke / 2)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeWidth = stroke
            color = track
        }
        canvas.drawArc(rect, 0f, 360f, false, paint)
        paint.color = ring
        paint.strokeCap = Paint.Cap.ROUND
        canvas.drawArc(rect, -90f, 360f * pct / 100f, false, paint)
        return bitmap
    }

    /** The card's glyph, generated from the app's icons (tool/gen_widget_glyphs.py). */
    fun glyph(context: Context, key: String): Int {
        val id = context.resources.getIdentifier("wg_$key", "drawable", context.packageName)
        return if (id != 0) id else R.drawable.wg_spark
    }

    /** Tints a white background shape (ImageView + shape drawable keeps the rounded corners). */
    fun RemoteViews.tint(viewId: Int, color: Int) {
        setInt(viewId, "setColorFilter", color or ALPHA_MASK)
        setInt(viewId, "setImageAlpha", color ushr 24)
    }

    /**
     * The status line. RemoteViews can't change a font weight, so each layout
     * has two copies — regular, and bold for an urgent one — and shows one.
     */
    fun status(v: RemoteViews, regularId: Int, boldId: Int, card: WidgetCard, colors: TierColors) {
        val shown = if (card.urgent) boldId else regularId
        v.setViewVisibility(regularId, if (card.urgent) android.view.View.GONE else android.view.View.VISIBLE)
        v.setViewVisibility(boldId, if (card.urgent) android.view.View.VISIBLE else android.view.View.GONE)
        v.setTextViewText(shown, card.status)
        v.setTextColor(shown, statusColor(card, colors))
    }

    /** The status line's colour — `CardStatus.color` in the app. */
    fun statusColor(card: WidgetCard, colors: TierColors): Int = when {
        !card.urgent -> withAlpha(colors.ink, 0.6f)
        card.tier == Tier.LATE -> colors.ink
        else -> colors.ring
    }

    fun withAlpha(color: Int, alpha: Float): Int =
        (((color ushr 24) * alpha).toInt() shl 24) or (color and 0xFFFFFF)

    private const val ALPHA_MASK = 0xFF000000.toInt()
}
