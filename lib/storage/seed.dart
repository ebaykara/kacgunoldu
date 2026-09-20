import '../domain/card.dart';
import '../domain/date.dart';
import '../l10n/strings.dart';
import '../l10n/strings_tr.dart';

/// First-launch content, matching the hifi mock card-for-card.
///
/// Each entry is `(name, daysSinceLastTime, gapsGoingBackwards)`, exactly the
/// shape the prototype used. Offsets are resolved against the real first-launch
/// date so the tiers, rings and overdue flags read as designed on day one.
///
/// The names come from the interface's language ([Strings.seedCards]); a card
/// keeps whatever name it was created under.
///
/// The ids stay keyed off the Turkish names whatever the language, so
/// "Örnek kartları ekle" still recognises a set that is already there after a
/// language switch — and so an install from before the English copy existed
/// keeps matching.
List<Card> seedCards([DateKey? today]) {
  final base = today ?? todayKey();
  final ids = const TrStrings().seedCards;
  return S.seedCards.indexed.map((pair) {
    final (index, entry) = pair;
    final (name, last, gaps) = entry;
    final offsets = <int>[last];
    var acc = last;
    for (final g in gaps) {
      acc += g;
      offsets.add(acc);
    }
    return Card(
      id: 'seed-${ids[index].$1}',
      name: name,
      recs: offsets.map((o) => shiftDays(base, -o)).toList(),
    );
  }).toList();
}
