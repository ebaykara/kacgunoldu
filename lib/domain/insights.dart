import 'dart:math' as math;

import 'card.dart';
import 'date.dart';
import 'logic.dart';

/// The profile screen's numbers — all derived from `recs` + today, never
/// stored, same as everything in `logic.dart`.

int totalRecords(List<Card> cards) =>
    cards.fold(0, (sum, c) => sum + c.recs.length);

/// Records that fall in the calendar month of [year]/[month].
int recordsInMonth(List<Card> cards, int year, int month) {
  var n = 0;
  for (final c in cards) {
    for (final r in c.recs) {
      final d = fromDateKey(r);
      if (d.year == year && d.month == month) n++;
    }
  }
  return n;
}

/// Cards started this month: the creation day when known, otherwise the
/// oldest record (seed and legacy cards carry no creation day).
int newCardsThisMonth(List<Card> cards, DateKey today) {
  final t = fromDateKey(today);
  var n = 0;
  for (final c in cards) {
    final start = c.created ?? (c.recs.isNotEmpty ? c.recs.last : null);
    if (start == null) continue;
    final d = fromDateKey(start);
    if (d.year == t.year && d.month == t.month) n++;
  }
  return n;
}

class MonthCount {
  const MonthCount(this.label, this.count);

  /// `Eyl`
  final String label;
  final int count;
}

/// Record counts for the last [n] calendar months, oldest first — the last
/// entry is the current month.
List<MonthCount> monthlyCounts(List<Card> cards, DateKey today, {int n = 6}) {
  final t = fromDateKey(today);
  return List.generate(n, (i) {
    final d = DateTime(t.year, t.month - (n - 1 - i));
    return MonthCount(
      monthsShort[d.month - 1],
      recordsInMonth(cards, d.year, d.month),
    );
  });
}

/// The card whose gaps vary the least relative to their size (lowest
/// coefficient of variation). Needs at least two gaps to judge; ties go to
/// the card with more history.
({Card card, int every})? mostRegular(List<Card> cards, DateKey today) {
  ({Card card, int every})? best;
  var bestScore = double.infinity;
  var bestGaps = 0;
  for (final c in cards) {
    final offsets = offsetsOf(c, today);
    if (offsets.length < 3) continue;
    final gaps = [
      for (var i = 0; i < offsets.length - 1; i++) offsets[i + 1] - offsets[i],
    ];
    final mean = gaps.reduce((a, b) => a + b) / gaps.length;
    if (mean <= 0) continue;
    final variance =
        gaps.map((g) => (g - mean) * (g - mean)).reduce((a, b) => a + b) /
        gaps.length;
    final score = math.sqrt(variance) / mean;
    if (score < bestScore - 1e-9 ||
        (score - bestScore).abs() < 1e-9 && gaps.length > bestGaps) {
      bestScore = score;
      bestGaps = gaps.length;
      best = (card: c, every: mean.round());
    }
  }
  return best;
}

/// The card left alone the longest.
({Card card, int days})? longestNeglected(List<Card> cards, DateKey today) {
  ({Card card, int days})? best;
  for (final c in cards) {
    if (c.recs.isEmpty) continue;
    final days = daysSince(c.recs.first, today);
    if (best == null || days > best.days) best = (card: c, days: days);
  }
  return best;
}
