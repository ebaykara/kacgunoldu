import 'card.dart';
import 'logic.dart';
import 'text.dart';

/// The chips above the grid: everything, only what is overdue, or only what
/// comes due soon.
enum CardFilter { all, late, soon }

const cardFilterLabels = {
  CardFilter.all: 'Tümü',
  CardFilter.late: 'Gecikenler',
  CardFilter.soon: 'Sırası yakın',
};

/// Show the search and filter bar from this many cards on; below it the whole
/// grid fits on a screen or two and the bar is only clutter.
const filterBarMinCards = 6;

/// The cards that pass [filter] and whose name — or a note on one of their
/// records — contains [query] (Turkish-aware, case-insensitive). Order is
/// kept.
List<DecoratedCard> filterCards(
  List<DecoratedCard> cards,
  CardFilter filter,
  String query,
) {
  final q = lowerTr(query.trim());
  bool matches(Card c) =>
      q.isEmpty ||
      lowerTr(c.name).contains(q) ||
      c.notes.values.any((n) => lowerTr(n).contains(q));
  return [
    for (final c in cards)
      if (switch (filter) {
            CardFilter.all => true,
            CardFilter.late => c.stats.isLate,
            CardFilter.soon => !c.stats.isLate && c.stats.tier == Tier.soon,
          } &&
          matches(c.card))
        c,
  ];
}
