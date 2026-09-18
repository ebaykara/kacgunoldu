import '../domain/card.dart';
import '../domain/date.dart';

/// First-launch content, matching the hifi mock card-for-card.
///
/// Each entry is `(name, daysSinceLastTime, gapsGoingBackwards)`, exactly the
/// shape the prototype used. Offsets are resolved against the real first-launch
/// date so the tiers, rings and overdue flags read as designed on day one.
///
/// Empty this list instead if the product should start blank.
const _seed = <(String, int, List<int>)>[
  ('Diş hekimine gittim', 214, [186, 192]),
  ('Spor salonuna gittim', 11, [3, 4, 2, 3]),
  ('Saçımı kestirdim', 46, [34, 38]),
  ('Çarşafları değiştirdim', 9, [11, 12, 10]),
  ('Anneme telefon ettim', 3, [4, 2, 5]),
  ('Bitkileri suladım', 5, [4, 3, 4]),
  ('Arabanın yağını değiştirdim', 121, [160, 175]),
  ('Buzdolabını temizledim', 28, [30, 26]),
  ('Yüzmeye gittim', 17, [9, 8, 11]),
];

List<Card> seedCards([DateKey? today]) {
  final base = today ?? todayKey();
  return _seed.map((entry) {
    final (name, last, gaps) = entry;
    final offsets = <int>[last];
    var acc = last;
    for (final g in gaps) {
      acc += g;
      offsets.add(acc);
    }
    return Card(
      id: 'seed-$name',
      name: name,
      recs: offsets.map((o) => shiftDays(base, -o)).toList(),
    );
  }).toList();
}
