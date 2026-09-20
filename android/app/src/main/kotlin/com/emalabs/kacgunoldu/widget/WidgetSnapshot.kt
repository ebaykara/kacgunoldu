package com.emalabs.kacgunoldu.widget

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.time.LocalDate
import java.time.temporal.ChronoUnit
import kotlin.math.min
import kotlin.math.roundToInt

/**
 * What the home screen widgets draw, as the app last wrote it
 * (lib/services/home_widgets.dart → MainActivity → here).
 *
 * The snapshot holds each card's last record and interval, never a day
 * count: the count is worked out here, against today, so a widget is right
 * after midnight without the app being opened. The rules are the app's own
 * (`statsFor` in lib/domain/logic.dart) — keep the two in step.
 */
internal class WidgetSnapshot(
    val theme: ThemeColors,
    /** Show the "Bugün yaptım" button (Ayarlar → Ana ekran widget'ı). */
    val doneButton: Boolean,
    /** The app's wording, in the language it is set to. */
    val strings: WidgetStrings,
    private val tiers: Map<Tier, TierColors>,
    cards: List<WidgetCard>,
) {
    /** Overdue first, then everything else, each by how far along it is. */
    val ordered: List<WidgetCard> = cards.filter { it.isLate }.sortedByDescending { it.ratio } +
        cards.filter { !it.isLate }.sortedByDescending { it.ratio }

    val lateCount: Int get() = ordered.count { it.isLate }

    fun colors(card: WidgetCard): TierColors = tiers[card.tier] ?: FALLBACK_TIER

    fun byId(id: String?): WidgetCard? = id?.let { wanted -> ordered.firstOrNull { it.id == wanted } }

    companion object {
        private const val PREFS = "kac_gun_oldu_widgets"
        private const val KEY = "snapshot"
        private const val MARKS = "marks"
        private const val VERSION = 1

        fun save(context: Context, json: String) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putString(KEY, json).apply()
        }

        /**
         * A widget's "Bugün yaptım": the card is done today. The widget
         * redraws from the snapshot at once (its `last` moved to today); the
         * mark waits in [MARKS] until the app takes it ([takeMarks]) and
         * turns it into a real record — CardStore._takeWidgetMarks.
         */
        fun markDone(context: Context, cardId: String, today: LocalDate = LocalDate.now()) {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val day = today.toString()
            val edit = prefs.edit()
            prefs.getString(KEY, null)?.let { raw ->
                try {
                    val o = JSONObject(raw)
                    val cards = o.getJSONArray("cards")
                    for (i in 0 until cards.length()) {
                        val c = cards.getJSONObject(i)
                        if (c.optString("id") == cardId) {
                            val last = if (c.isNull("last")) null else c.optString("last")
                            if (last == null || last < day) c.put("last", day)
                        }
                    }
                    edit.putString(KEY, o.toString())
                } catch (_: Exception) {
                }
            }
            val marks = try {
                JSONArray(prefs.getString(MARKS, "[]"))
            } catch (_: Exception) {
                JSONArray()
            }
            marks.put(JSONObject().put("id", cardId).put("day", day))
            edit.putString(MARKS, marks.toString()).apply()
        }

        /** The marks not yet recorded by the app, as JSON; clears them. */
        fun takeMarks(context: Context): String {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val marks = prefs.getString(MARKS, null) ?: return "[]"
            prefs.edit().remove(MARKS).apply()
            return marks
        }

        /** `null` until the app has run once since the widgets shipped. */
        fun load(context: Context, today: LocalDate = LocalDate.now()): WidgetSnapshot? {
            val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY, null)
                ?: return null
            return try {
                parse(JSONObject(raw), today)
            } catch (_: Exception) {
                null
            }
        }

        private fun parse(o: JSONObject, today: LocalDate): WidgetSnapshot? {
            if (o.optInt("v") > VERSION) return null
            val t = o.getJSONObject("theme")
            val theme = ThemeColors(
                dark = t.optBoolean("dark"),
                surface = t.color("surface"),
                onSurface = t.color("onSurface"),
                muted = t.color("muted"),
                outline = t.color("outline"),
                primary = t.color("primary"),
                onPrimary = t.color("onPrimary"),
            )
            val strings = WidgetStrings.parse(o.optJSONObject("strings"))
            val tierJson = o.getJSONObject("tiers")
            val tiers = Tier.values().associateWith { tier ->
                val c = tierJson.getJSONObject(tier.key)
                TierColors(c.color("bg"), c.color("ink"), c.color("ring"), c.color("track"))
            }
            val list = o.getJSONArray("cards")
            val cards = (0 until list.length()).mapNotNull { i ->
                val c = list.getJSONObject(i)
                val id = c.optString("id")
                if (id.isEmpty()) return@mapNotNull null
                WidgetCard(
                    id = id,
                    name = c.optString("name"),
                    icon = c.optString("icon"),
                    last = if (c.isNull("last")) null else runCatching { LocalDate.parse(c.getString("last")) }.getOrNull(),
                    typical = if (c.isNull("typical")) null else c.optInt("typical").takeIf { it > 0 },
                    today = today,
                    strings = strings,
                )
            }
            return WidgetSnapshot(theme, o.optBoolean("doneButton", true), strings, tiers, cards)
        }

        private fun JSONObject.color(key: String): Int = getLong(key).toInt()
    }
}

/**
 * The text the widgets draw, as the app last published it
 * (`Strings.widgetStrings` in lib/l10n). `{n}` is the number this side works
 * out. The fallbacks are the Turkish originals, for a widget placed before
 * the app has ever run.
 */
internal class WidgetStrings(private val map: Map<String, String>) {
    private fun s(key: String, fallback: String) = map[key]?.takeIf { it.isNotEmpty() } ?: fallback
    private fun fmt(key: String, fallback: String, value: Int) = s(key, fallback).replace("{n}", value.toString())

    val title: String get() = s("title", "Kaç gün oldu?")
    fun late(n: Int): String = fmt("late", "{n} kart gecikti", n)
    val notMarked: String get() = s("notMarked", "Henüz işaretlenmedi")
    val learning: String get() = s("learning", "Ritim öğreniliyor")
    fun daysLeft(n: Int): String = fmt("daysLeft", "{n} gün kaldı", n)
    val dueToday: String get() = s("dueToday", "Bugün sırası")
    fun daysOver(n: Int): String = fmt("daysOver", "{n} gün geçti", n)
    val unitDays: String get() = s("unitDays", "gün oldu")
    val unitNone: String get() = s("unitNone", "kayıt yok")
    val doneToday: String get() = s("doneToday", "Bugün yapıldı")
    val markDone: String get() = s("markDone", "Bugün yaptım")
    val firstCard: String get() = s("firstCard", "İlk kartını oluştur")
    val openApp: String get() = s("openApp", "Kartlarını görmek için uygulamayı aç")

    companion object {
        val DEFAULT = WidgetStrings(emptyMap())

        fun parse(o: JSONObject?): WidgetStrings {
            if (o == null) return DEFAULT
            val map = HashMap<String, String>()
            for (key in o.keys()) o.optString(key).let { if (it.isNotEmpty()) map[key] = it }
            return WidgetStrings(map)
        }
    }
}

internal enum class Tier(val key: String) { FRESH("fresh"), CALM("calm"), SOON("soon"), LATE("late") }

internal class TierColors(val bg: Int, val ink: Int, val ring: Int, val track: Int)

internal class ThemeColors(
    val dark: Boolean,
    val surface: Int,
    val onSurface: Int,
    val muted: Int,
    val outline: Int,
    val primary: Int,
    val onPrimary: Int,
) {
    companion object {
        /** Kiremit, the default theme — for a widget placed before the app ever ran. */
        val DEFAULT = ThemeColors(
            dark = false,
            surface = 0xFFFBF5F0.toInt(),
            onSurface = 0xFF241F1B.toInt(),
            muted = 0xFF87786C.toInt(),
            outline = 0xFFE6D9CF.toInt(),
            primary = 0xFFB8492A.toInt(),
            onPrimary = 0xFFFFF3EA.toInt(),
        )
    }
}

private val FALLBACK_TIER = TierColors(
    0xFFFFFDFA.toInt(), 0xFF241F1B.toInt(), 0xFFC98A6B.toInt(), 0x1A241F1B,
)

/** One card, with everything the app's `statsFor` derives from it. */
internal class WidgetCard(
    val id: String,
    val name: String,
    val icon: String,
    val last: LocalDate?,
    val typical: Int?,
    today: LocalDate,
    strings: WidgetStrings = WidgetStrings.DEFAULT,
) {
    val days: Int = last?.let { ChronoUnit.DAYS.between(it, today).toInt().coerceAtLeast(0) } ?: 0

    val ratio: Double = if (typical != null && typical != 0) {
        days.toDouble() / typical
    } else {
        min(0.95, days / 30.0)
    }

    /** `+1` keeps short-interval cards from flagging on a single late day. */
    val isLate: Boolean = typical != null && last != null && days > typical * 1.25 + 1

    val tier: Tier = when {
        isLate -> Tier.LATE
        ratio > 0.95 -> Tier.SOON
        ratio < 0.5 -> Tier.FRESH
        else -> Tier.CALM
    }

    /** Ring fill, 3–100. */
    val pct: Int = (ratio * 100).roundToInt().coerceIn(3, 100)

    /** Days left in the usual interval; negative past it, `null` while learning. */
    val remaining: Int? = if (typical == null || last == null) null else typical - days

    /** The card's one status line — `CardStatus` in lib/widgets/card_status.dart. */
    val status: String = when {
        last == null -> strings.notMarked
        remaining == null -> strings.learning
        remaining > 0 -> strings.daysLeft(remaining)
        remaining == 0 -> strings.dueToday
        else -> strings.daysOver(-remaining)
    }

    /** Due today or past due: drawn in the accent, bold. */
    val urgent: Boolean = remaining != null && remaining <= 0

    /** Already recorded today: the "Bugün yaptım" button shows it's done. */
    val doneToday: Boolean = last == today

    /** The big number, or a dash when nothing is recorded yet. */
    val dayText: String = if (last == null) "—" else days.toString()
    val unitText: String = if (last == null) strings.unitNone else strings.unitDays
}
