import 'package:flutter_test/flutter_test.dart';
import 'package:kac_gun_oldu/domain/card.dart';
import 'package:kac_gun_oldu/domain/date.dart';
import 'package:kac_gun_oldu/domain/frequency.dart';
import 'package:kac_gun_oldu/domain/icon_guess.dart';
import 'package:kac_gun_oldu/domain/insights.dart';
import 'package:kac_gun_oldu/domain/logic.dart';
import 'package:kac_gun_oldu/domain/text.dart';

const today = '2026-09-18';

Card card(String name, List<int> offsets, {int? every, DateKey? created}) =>
    Card(
      id: name,
      name: name,
      recs: offsets.map((o) => shiftDays(today, -o)).toList(),
      every: every,
      created: created,
    );

void main() {
  group('declared rhythm', () {
    test('wins over the learned median', () {
      // Learned median 3; declared weekly.
      final s = statsFor(card('x', [5, 8, 11, 14], every: 7), today);
      expect(s.typical, 7);
      expect(s.ringLabel, '2 gün');
      // Same non-breaking spaces as every meta line.
      expect(s.meta, '13 Eylül ~7 günde bir');
    });

    test('gives a card a rhythm before it has three records', () {
      final s = statsFor(card('x', [20], every: 7), today);
      expect(s.typical, 7);
      // 20 > 7 * 1.25 + 1
      expect(s.isLate, isTrue);
      expect(s.ringLabel, '+13 gün');
    });

    test('never makes a card with no records late', () {
      final s = statsFor(card('x', [], every: 1), today);
      expect(s.isLate, isFalse);
      expect(s.ringLabel, 'yeni');
    });
  });

  group('averageGap', () {
    test('is the mean gap, even with a single gap', () {
      expect(averageGap(card('x', [3, 10]), today), 7);
      expect(averageGap(card('x', [0, 4, 8, 15]), today), 5);
    });

    test('is null under two records', () {
      expect(averageGap(card('x', [3]), today), isNull);
    });
  });

  group('profile numbers', () {
    final cards = [
      card('a', [0, 5, 40]),
      card('b', [2, 35], created: '2026-09-02'),
      card('c', [214, 400]),
    ];

    test('counts records per month', () {
      expect(totalRecords(cards), 7);
      expect(recordsInMonth(cards, 2026, 9), 3);
      expect(recordsInMonth(cards, 2026, 8), 2);
    });

    test(
      'counts cards started this month by creation day or oldest record',
      () {
        expect(newCardsThisMonth(cards, today), 1);
        expect(
          newCardsThisMonth([
            card('d', [3]),
          ], today),
          1,
        );
      },
    );

    test('lists the last six months, oldest first', () {
      final m = monthlyCounts(cards, today);
      expect(m.map((e) => e.label), ['Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl']);
      expect(m.last.count, 3);
    });

    test('picks the steadiest card and the most neglected one', () {
      final steady = card('steady', [1, 5, 9, 13]);
      final jumpy = card('jumpy', [1, 2, 12, 14]);
      final r = mostRegular([jumpy, steady], today)!;
      expect(r.card.name, 'steady');
      expect(r.every, 4);
      expect(longestNeglected(cards, today)!.card.name, 'c');
      expect(
        mostRegular([
          card('x', [1, 5]),
        ], today),
        isNull,
      );
    });
  });

  group('glyph guessing', () {
    test('matches the seed cards to their glyphs', () {
      expect(guessIcon('Diş hekimine gittim'), 'tooth');
      expect(guessIcon('Spor salonuna gittim'), 'gym');
      expect(guessIcon('Yüzmeye gittim'), 'swim');
      expect(guessIcon('Çarşafları değiştirdim'), 'bed');
      expect(guessIcon('Saçımı kestirdim'), 'scissors');
      expect(guessIcon('Bitkileri suladım'), 'plant');
      expect(guessIcon('Buzdolabını temizledim'), 'fridge');
      expect(guessIcon('Arabanın yağını değiştirdim'), 'car');
      expect(guessIcon('Anneme telefon ettim'), 'phone');
    });

    test('is case-insensitive the Turkish way and falls back', () {
      expect(guessIcon('İLAÇ ALDIM'), 'pill');
      expect(guessIcon('Pasaportu yeniledim'), defaultIconKey);
    });
  });

  test('frequency labels', () {
    expect(frequencyLabel(7), 'Haftada bir');
    expect(frequencyLabel(10), '10 günde bir');
    expect(isPresetFrequency(365), isTrue);
    expect(isPresetFrequency(10), isFalse);
  });

  test('Turkish lowercasing and initials', () {
    expect(lowerTr('IŞIK İNCİ'), 'ışık inci');
    expect(initialsOf('eyüp baykara'), 'EB');
    expect(initialsOf('  inci '), 'İ');
    expect(initialsOf(''), '');
  });

  group('card JSON', () {
    test('round-trips the optional fields', () {
      const c = Card(
        id: 'a',
        name: 'A',
        recs: ['2026-09-18'],
        icon: 'gym',
        every: 3,
        created: '2026-09-01',
      );
      final back = Card.tryFromJson(c.toJson())!;
      expect(back.icon, 'gym');
      expect(back.every, 3);
      expect(back.created, '2026-09-01');
    });

    test('ignores a malformed optional field instead of dropping the card', () {
      final back = Card.tryFromJson({
        'id': 'a',
        'name': 'A',
        'recs': ['2026-09-18'],
        'every': -2,
        'icon': 7,
        'created': 'yesterday',
      })!;
      expect(back.every, isNull);
      expect(back.icon, isNull);
      expect(back.created, isNull);
    });

    test('leaves the optional fields out when unset', () {
      const c = Card(id: 'a', name: 'A', recs: []);
      expect(c.toJson().keys, ['id', 'name', 'recs']);
    });
  });
}
