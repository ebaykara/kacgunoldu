import 'dart:math' as math;
import 'dart:ui' show Color;

import '../l10n/strings.dart';
import '../theme/tokens.dart';
import 'card.dart';
import 'date.dart';

/// Palette per tier — the card's whole colour identity.
class TierPalette {
  const TierPalette({
    required this.bg,
    required this.ink,
    required this.ring,
    required this.track,
    required this.tag,
  });

  final Color bg;
  final Color ink;
  final Color ring;
  final Color track;
  final Color tag;
}

/// Rebuilt from [AppColor] on each read so a theme change takes effect.
/// Tracks are the tier's ink at low alpha (rgba(31,42,20,.13) etc. in the
/// default theme).
Map<Tier, TierPalette> get tiers => {
      Tier.fresh: TierPalette(
        bg: AppColor.tertiaryContainer,
        ink: AppColor.onTertiaryContainer,
        ring: AppColor.tertiary,
        track: AppColor.onTertiaryContainer.withValues(alpha: 0.13),
        tag: AppColor.tertiary,
      ),
      Tier.calm: TierPalette(
        bg: AppColor.surfaceBright,
        ink: AppColor.onSurface,
        ring: AppColor.primaryDim,
        track: AppColor.onSurface.withValues(alpha: 0.10),
        tag: AppColor.primaryDim,
      ),
      Tier.soon: TierPalette(
        bg: AppColor.primaryContainer,
        ink: AppColor.onPrimaryContainer,
        ring: AppColor.primary,
        track: AppColor.onPrimaryContainer.withValues(alpha: 0.14),
        tag: AppColor.primary,
      ),
      Tier.late: TierPalette(
        bg: AppColor.primary,
        ink: AppColor.onPrimary,
        ring: AppColor.ringOnPrimary,
        track: AppColor.onPrimary.withValues(alpha: 0.28),
        tag: AppColor.onPrimary.withValues(alpha: 0.22),
      ),
    };

/// Day offsets of a card's records, ascending in age (`[0]` = most recent).
List<int> offsetsOf(Card card, DateKey today) =>
    card.recs.map((r) => daysSince(r, today)).toList();

/// Median gap between consecutive records.
///
/// `null` under three records (fewer than two gaps) — one gap is not a rhythm,
/// and a card without a typical interval can never be flagged overdue.
int? typicalInterval(List<int> offsets) {
  final gaps = <int>[];
  for (var i = 0; i < offsets.length - 1; i++) {
    gaps.add(offsets[i + 1] - offsets[i]);
  }
  if (gaps.length < 2) return null;
  final s = [...gaps]..sort();
  return s.length.isOdd
      ? s[(s.length - 1) ~/ 2]
      : ((s[s.length ~/ 2 - 1] + s[s.length ~/ 2]) / 2).round();
}

/// Everything the UI needs about a card, derived fresh from `recs` + today.
class CardStats {
  const CardStats({
    required this.days,
    required this.typical,
    required this.ratio,
    required this.isLate,
    required this.tier,
    required this.pct,
    required this.remaining,
    required this.ringLabel,
    required this.ringHint,
    required this.meta,
  });

  /// Days since the most recent record.
  final int days;

  /// Median interval, or `null` while the card is still learning.
  final int? typical;

  /// `days / typical`, or a gentle `days / 30` ramp while learning.
  final double ratio;

  final bool isLate;
  final Tier tier;

  /// Ring fill, 3–100%.
  final int pct;

  /// Days left before this is due again — negative once past due, `null`
  /// while the card is still learning its interval.
  final int? remaining;

  /// Text inside the ring: `4 gün`, `bugün`, `+8 gün`, or `yeni`.
  final String ringLabel;

  /// The ring, spelled out for screen readers.
  final String ringHint;

  /// The card's meta line.
  final String meta;
}

/// Derives every displayed value from `recs` + today.
///
/// Overdue is `days > typical * 1.25 + 1`: the `+1` keeps short-interval cards
/// (water the plants every 3 days) from flagging on a single late day.
CardStats statsFor(Card card, DateKey today) {
  final offsets = offsetsOf(card, today);
  final days = offsets.isNotEmpty ? offsets[0] : 0;
  // A declared rhythm ("haftada bir") is the person's own answer and wins;
  // otherwise the interval is learned from the records.
  final typical = card.every ?? typicalInterval(offsets);
  final ratio = typical != null && typical != 0
      ? days / typical
      : math.min(0.95, days / 30);
  final isLate =
      typical != null && card.recs.isNotEmpty && days > typical * 1.25 + 1;
  final tier = isLate
      ? Tier.late
      : ratio > 0.95
          ? Tier.soon
          : ratio < 0.5
              ? Tier.fresh
              : Tier.calm;
  final pct = math.max(3, math.min(100, (ratio * 100).round()));

  // Always the same shape — last date + the learned interval — whether the
  // card is late or not. The overdue amount already lives in the ring
  // (`+8 gün`) and in the `8 gün gecikti` tag; repeating it here in a third
  // phrasing was the confusing part.
  //
  // No "·" between the two halves — it read as a stray line. A plain space is
  // enough of a break, and a non-breaking space keeps "günde bir" from
  // splitting across a wrap (the Text itself is also capped at one line).
  final lastKey = card.recs.isNotEmpty ? card.recs[0] : null;
  final meta = lastKey == null
      ? S.notMarkedYet
      : days == 0
          ? S.doneTodayMeta
          : typical != null
              ? S.metaEvery(formatDayMonth(lastKey, today), typical)
              : formatDayMonth(lastKey, today);

  // The ring answers one question: how long until this is due again?
  //
  // `4 gün` means four days of the usual interval are left, `bugün` means it
  // is due today, `+8 gün` means it is eight days past the usual interval, and
  // `yeni` means the card has not learned an interval yet. The arc is the same
  // value drawn as progress through the interval.
  final remaining =
      typical == null || card.recs.isEmpty ? null : typical - days;
  final ringLabel = remaining == null
      ? S.ringNew
      : remaining > 0
          ? S.ringDays(remaining)
          : remaining == 0
              ? S.ringToday
              : S.ringOver(-remaining);
  final ringHint = remaining == null
      ? S.ringHintNew
      : remaining > 0
          ? S.ringHintLeft(remaining)
          : remaining == 0
              ? S.ringHintDueToday
              : S.ringHintOver(-remaining);

  return CardStats(
    days: days,
    typical: typical,
    ratio: ratio,
    isLate: isLate,
    tier: tier,
    pct: pct,
    remaining: remaining,
    ringLabel: ringLabel,
    ringHint: ringHint,
    meta: meta,
  );
}

/// A card plus everything derived from it, ready to render.
class DecoratedCard {
  DecoratedCard(this.card, this.stats);

  final Card card;
  final CardStats stats;

  String get id => card.id;
  String get name => card.name;
}

DecoratedCard decorate(Card card, DateKey today) =>
    DecoratedCard(card, statsFor(card, today));

/// Overdue cards first, then everything else — each group by `ratio`
/// descending, so the most-neglected thing is always the first card on screen.
List<DecoratedCard> orderCards(List<DecoratedCard> cards) {
  final late = cards.where((c) => c.stats.isLate).toList()
    ..sort((a, b) => b.stats.ratio.compareTo(a.stats.ratio));
  final rest = cards.where((c) => !c.stats.isLate).toList()
    ..sort((a, b) => b.stats.ratio.compareTo(a.stats.ratio));
  return [...late, ...rest];
}

/// Mean gap between consecutive records, rounded — the "Ortalama" figure.
/// Unlike [typicalInterval] a single gap is enough; `null` with none.
int? averageGap(Card card, DateKey today) {
  final offsets = offsetsOf(card, today);
  if (offsets.length < 2) return null;
  return ((offsets.last - offsets.first) / (offsets.length - 1)).round();
}
