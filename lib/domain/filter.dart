import '../l10n/strings.dart';
import 'card.dart';
import 'logic.dart';
import 'text.dart';

/// The chips above the grid: everything, only what is overdue, or only what
/// comes due soon.
enum CardFilter { all, late, soon }

Map<CardFilter, String> get cardFilterLabels => {
  CardFilter.all: S.filterAll,
  CardFilter.late: S.filterLate,
  CardFilter.soon: S.filterSoon,
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
  final needles = foldedForms(query.trim());
  bool hit(String text) {
    final forms = foldedForms(text);
    return needles.any((q) => forms.any((f) => f.contains(q)));
  }

  bool matches(Card c) =>
      query.trim().isEmpty || hit(c.name) || c.notes.values.any(hit);
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
