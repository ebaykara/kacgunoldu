import 'package:flutter_test/flutter_test.dart';
import 'package:kac_gun_oldu/domain/card.dart';
import 'package:kac_gun_oldu/domain/date.dart';
import 'package:kac_gun_oldu/domain/logic.dart';

const today = '2026-09-18';

/// Build a card whose records sit [offsets] days before [today].
Card card(String name, List<int> offsets) => Card(
      id: name,
      name: name,
      recs: offsets.map((o) => shiftDays(today, -o)).toList(),
    );

void main() {
  group('typicalInterval', () {
    test('is null under three records — one gap is not a rhythm', () {
      expect(typicalInterval([]), isNull);
      expect(typicalInterval([5]), isNull);
      expect(typicalInterval([5, 12]), isNull);
    });

    test('is the middle gap for an odd count', () {
      // gaps: 3, 10, 4 -> sorted 3, 4, 10
      expect(typicalInterval([0, 3, 13, 17]), 4);
    });

    test('rounds the mean of the middle two for an even count', () {
      // gaps: 3, 4, 2, 3 -> sorted 2, 3, 3, 4 -> (3 + 3) / 2
      expect(typicalInterval([11, 14, 18, 20, 23]), 3);
      // gaps: 186, 192 -> (186 + 192) / 2 = 189
      expect(typicalInterval([214, 400, 592]), 189);
    });
  });

  group('overdue rule', () {
    test('never flags a card that has not learned an interval yet', () {
      final s = statsFor(card('yeni', [400, 800]), today);
      expect(s.typical, isNull);
      expect(s.isLate, isFalse);
      expect(s.ringLabel, 'yeni');
    });

    test('flags a card past typical * 1.25 + 1', () {
      // typical 3; threshold 4.75; 11 days since
      final s = statsFor(card('Spor salonuna gittim', [11, 14, 18, 20, 23]), today);
      expect(s.typical, 3);
      expect(s.isLate, isTrue);
      expect(s.tier, Tier.late);
    });

    test('gives short-interval cards a one-day grace', () {
      // typical 4; threshold 6. Five days late is still calm, seven is not.
      expect(statsFor(card('Bitkileri suladım', [5, 9, 12, 16]), today).isLate, isFalse);
      expect(statsFor(card('Bitkileri suladım', [7, 11, 14, 18]), today).isLate, isTrue);
    });

    test('does not flag exactly at the threshold', () {
      // typical 36; threshold 46; 46 days since -> not late, but `soon`
      final s = statsFor(card('Saçımı kestirdim', [46, 80, 118]), today);
      expect(s.typical, 36);
      expect(s.isLate, isFalse);
      expect(s.tier, Tier.soon);
    });
  });

  group('a card with no records yet', () {
    // Reachable through "Ekle ve tarih seç", which creates the card before the
    // date is picked.
    const empty = Card(id: 'empty', name: 'yeni kart', recs: []);

    test('renders without a last-record date', () {
      final s = statsFor(empty, today);
      expect(s.days, 0);
      expect(s.typical, isNull);
      expect(s.isLate, isFalse);
      expect(s.meta, 'Henüz işaretlenmedi');
      expect(s.remaining, isNull);
      expect(s.ringLabel, 'yeni');
      expect(s.pct, 3);
    });
  });

  group('tier and ring', () {
    test('walks late -> soon -> calm -> fresh as the ratio falls', () {
      Tier tierFor(int days) =>
          statsFor(card('x', [days, days + 10, days + 20, days + 30]), today).tier;
      expect(tierFor(20), Tier.late); // ratio 2.0
      expect(tierFor(11), Tier.soon); // ratio 1.1
      expect(tierFor(7), Tier.calm); // ratio 0.7
      expect(tierFor(4), Tier.fresh); // ratio 0.4
    });

    test('clamps the ring between 3% and 100%', () {
      expect(statsFor(card('x', [0, 10, 20, 30]), today).pct, 3);
      expect(statsFor(card('x', [60, 70, 80, 90]), today).pct, 100);
    });

    test('reads the ring as time left, not as a ratio', () {
      // typical 4, two days since -> two days of the interval left
      final soon = statsFor(card('x', [2, 6, 9, 13]), today);
      expect(soon.remaining, 2);
      expect(soon.ringLabel, '2 gün');
      expect(soon.ringHint, 'her zamanki aralığa 2 gün kaldı');

      // typical 4, four days since -> due today
      expect(statsFor(card('x', [4, 8, 11, 15]), today).ringLabel, 'bugün');

      // typical 3, eleven days since -> eight days past the usual interval
      final late = statsFor(card('x', [11, 14, 18, 20, 23]), today);
      expect(late.remaining, -8);
      expect(late.ringLabel, '+8 gün');
      expect(late.ringHint, 'her zamanki aralığı 8 gün aştı');
    });
  });

  group('meta line', () {
    test('keeps the same shape whether a card is late or not', () {
      // The overdue amount lives in the ring and the tag, not here — repeating
      // it in a third phrasing was the confusing part.
      final s = statsFor(card('Spor salonuna gittim', [11, 14, 18, 20, 23]), today);
      expect(s.isLate, isTrue);
      expect(s.meta, '7 Eylül ~3 günde bir');
    });

    test('reads "Bugün yapıldı" the day it is recorded', () {
      expect(statsFor(card('x', [0, 4, 8, 12]), today).meta, 'Bugün yapıldı');
    });

    test('pairs the date with the learned interval', () {
      expect(statsFor(card('x', [5, 9, 12, 16]), today).meta, '13 Eylül ~4 günde bir');
    });

    test('appends the year once the record leaves the current one', () {
      expect(statsFor(card('x', [300, 700]), today).meta, '22 Kasım 2025');
    });

    test('never wraps "günde bir" — the two words are joined', () {
      final meta = statsFor(card('x', [5, 9, 12, 16]), today).meta;
      // No "·" separator, and no plain space inside "günde bir".
      expect(meta.contains('·'), isFalse);
      expect(meta.contains('günde bir'), isFalse);
      expect(meta.contains('günde bir'), isTrue);
    });
  });

  group('calendar-day arithmetic', () {
    test('counts whole calendar days, not 24h blocks', () {
      expect(daysSince('2026-09-17', '2026-09-18'), 1);
      expect(daysSince('2026-09-18', '2026-09-18'), 0);
      expect(daysSince('2025-12-31', '2026-01-01'), 1);
    });

    test('survives a DST boundary', () {
      // Both ends are pinned to local midnight before subtracting, so a 23h or
      // 25h day still reads as exactly one day.
      expect(daysSince('2026-03-28', '2026-03-29'), 1);
      expect(daysSince('2026-10-24', '2026-10-25'), 1);
    });

    test('rolls a card over at midnight rather than 24h after the tap', () {
      final justBefore = DateTime(2026, 9, 18, 23, 59, 30);
      final justAfter = DateTime(2026, 9, 19, 0, 0, 30);
      expect(toDateKey(justBefore), '2026-09-18');
      expect(toDateKey(justAfter), '2026-09-19');

      // A card recorded at 23:59 reads "1 gün" thirty seconds later.
      expect(daysSince('2026-09-18', toDateKey(justAfter)), 1);
    });

    test('schedules the next rollover inside the coming day', () {
      final d = untilMidnight(DateTime(2026, 9, 18, 23, 59, 0));
      expect(d.inMilliseconds, greaterThan(0));
      expect(d.inMilliseconds, lessThanOrEqualTo(24 * 60 * 60 * 1000));
    });
  });

  group('weekday names', () {
    test('map Dart weekdays onto the Turkish abbreviations', () {
      // DateTime.weekday is Monday=1 … Sunday=7; the table is Sunday-first,
      // so the day grid indexes it with `weekday % 7`.
      String abbrev(DateTime d) => dow[d.weekday % 7];
      expect(abbrev(DateTime(2026, 9, 14)), 'Pzt'); // a Monday
      expect(abbrev(DateTime(2026, 9, 18)), 'Cum'); // a Friday
      expect(abbrev(DateTime(2026, 9, 19)), 'Cmt'); // a Saturday
      expect(abbrev(DateTime(2026, 9, 20)), 'Paz'); // a Sunday
    });
  });

  group('relativeLabel', () {
    test('matches the copy in the handoff', () {
      expect(relativeLabel(0), 'bugün');
      expect(relativeLabel(1), 'dün');
      expect(relativeLabel(6), '6 gün önce');
      expect(relativeLabel(14), '2 hafta önce');
      expect(relativeLabel(59), '8 hafta önce');
      expect(relativeLabel(90), '3 ay önce');
    });
  });
}
