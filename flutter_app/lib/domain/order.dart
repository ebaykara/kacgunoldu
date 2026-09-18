import 'card.dart';
import 'date.dart';
import 'logic.dart';

/// The grid's actual display order.
///
/// With no saved arrangement, cards sort by urgency (overdue first, then
/// soonest-due) — see [orderCards]. Once someone drags a card, [manualOrder]
/// holds the exact id sequence they left it in, and that wins from then on.
///
/// A card missing from [manualOrder] — just created, or from before dragging
/// existed — sorts to the front, matching where a new card has always appeared
/// in this app. Ties keep their incoming order, since [List.sort]'s comparator
/// is applied to a stable merge sort in the Dart SDK.
List<Card> applyOrder(List<Card> cards, List<String>? manualOrder, DateKey today) {
  if (manualOrder != null && manualOrder.isNotEmpty) {
    final position = <String, int>{
      for (var i = 0; i < manualOrder.length; i++) manualOrder[i]: i,
    };
    final sorted = [...cards];
    _stableSort(sorted, (a, b) {
      final pa = position[a.id] ?? -1;
      final pb = position[b.id] ?? -1;
      return pa.compareTo(pb);
    });
    return sorted;
  }

  final decorated = cards.map((c) => decorate(c, today)).toList();
  final byId = {for (final c in cards) c.id: c};
  return orderCards(decorated).map((d) => byId[d.id]!).toList();
}

/// Dart's [List.sort] is *not* guaranteed stable, so equal keys could swap.
/// Two cards with no saved position must keep their relative order, so the
/// index is folded into the comparison as a tiebreak.
void _stableSort<T>(List<T> list, int Function(T a, T b) compare) {
  final indexed = <(int, T)>[
    for (var i = 0; i < list.length; i++) (i, list[i]),
  ];
  indexed.sort((a, b) {
    final c = compare(a.$2, b.$2);
    return c != 0 ? c : a.$1.compareTo(b.$1);
  });
  for (var i = 0; i < list.length; i++) {
    list[i] = indexed[i].$2;
  }
}
