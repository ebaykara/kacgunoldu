import 'package:flutter_test/flutter_test.dart';
import 'package:kac_gun_oldu/domain/card.dart';
import 'package:kac_gun_oldu/domain/date.dart';
import 'package:kac_gun_oldu/domain/filter.dart';
import 'package:kac_gun_oldu/domain/logic.dart';
import 'package:kac_gun_oldu/domain/order.dart';
import 'package:kac_gun_oldu/domain/reminders.dart';
import 'package:kac_gun_oldu/domain/share.dart';
import 'package:kac_gun_oldu/domain/templates.dart';
import 'package:kac_gun_oldu/widgets/card_glyph.dart';
import 'package:kac_gun_oldu/widgets/gap_chart.dart';

const today = '2026-09-18';

Card card(
  String id,
  List<int> offsets, {
  String? name,
  int? every,
  Map<DateKey, String> notes = const {},
  bool notify = false,
  bool archived = false,
  int? remindAt,
}) =>
    Card(
      id: id,
      name: name ?? id,
      recs: offsets.map((o) => shiftDays(today, -o)).toList(),
      every: every,
      notes: notes,
      notify: notify,
      archived: archived,
      remindAt: remindAt,
    );

void main() {
  group('Card json', () {
    test('notes, archived and remindAt round-trip', () {
      final c = card(
        'a',
        [0, 10],
        notes: {shiftDays(today, -10): '45.200 km'},
        archived: true,
        remindAt: 20 * 60 + 30,
      );
      final back = Card.tryFromJson(c.toJson())!;
      expect(back.notes, {shiftDays(today, -10): '45.200 km'});
      expect(back.archived, isTrue);
      expect(back.remindAt, 1230);
    });

    test('the new fields are only written when set', () {
      final json = card('a', [0]).toJson();
      expect(json.containsKey('notes'), isFalse);
      expect(json.containsKey('archived'), isFalse);
      expect(json.containsKey('remindAt'), isFalse);
    });

    test('a bad optional field is dropped, not the card', () {
      final back = Card.tryFromJson({
        'id': 'a',
        'name': 'A',
        'recs': ['2026-09-01'],
        'notes': {'2026-01-01': 'no such record', '2026-09-01': 7},
        'remindAt': 5000,
        'archived': 'yes',
      })!;
      expect(back.notes, isEmpty);
      expect(back.remindAt, isNull);
      expect(back.archived, isFalse);
    });
  });

  group('sharing', () {
    test('a card survives the link, Turkish letters and notes included', () {
      final c = card(
        'x',
        [2, 9, 16],
        name: 'Çiçekleri ığdırlı suladım',
        every: 7,
        notes: {shiftDays(today, -9): 'gübre de verildi'},
        notify: true,
        remindAt: 60,
      );
      final back = parseSharedCard(shareMessage(c))!;
      expect(back.name, c.name);
      expect(back.every, 7);
      expect(back.recs, c.recs);
      expect(back.notes, c.notes);
      // What is about this device does not travel.
      expect(back.id, '');
      expect(back.notify, isFalse);
      expect(back.remindAt, isNull);
    });

    test('the path alone is enough (how Flutter hands a link over)', () {
      final link = shareLink(card('x', [1], name: 'Yağ değişimi'));
      final path = link.substring('kacgunoldu://app'.length);
      expect(path, startsWith('/share/'));
      expect(parseSharedCard(path)!.name, 'Yağ değişimi');
    });

    test('anything else is not a card', () {
      expect(parseSharedCard('merhaba'), isNull);
      expect(parseSharedCard('kacgunoldu://app/share/!!!'), isNull);
      expect(parseSharedCard('kacgunoldu://app/share/bm90anNvbg'), isNull);
      expect(parseSharedCard('kacgunoldu://app/card/abc'), isNull);
    });
  });

  test('CSV: one row per record, quoted where needed', () {
    final csv = cardsCsv([
      card(
        'a',
        [0, 3],
        name: 'Yağ, filtre',
        notes: {today: 'dedi ki "tamam"'},
      ),
      card('b', []),
    ]);
    final lines = csv.split('\r\n');
    expect(lines[0], 'Kart,Tarih,Not');
    expect(lines[1], '"Yağ, filtre",$today,"dedi ki ""tamam"""');
    expect(lines[2], '"Yağ, filtre",${shiftDays(today, -3)},');
    expect(lines.length, 4); // trailing empty after the last CRLF
  });

  group('filterCards', () {
    List<DecoratedCard> deck() => [
          // late: typical 4, 10 days since
          decorate(card('Geç', [10, 14, 18, 22]), today),
          // soon: typical 4, 4 days since
          decorate(card('Yakın', [4, 8, 12, 16]), today),
          // fresh
          decorate(
            card(
              'İlaç',
              [0, 4, 8],
              notes: {shiftDays(today, -4): 'Doz iki katına çıktı'},
            ),
            today,
          ),
        ];

    test('by state', () {
      expect(filterCards(deck(), CardFilter.all, '').length, 3);
      expect(
        filterCards(deck(), CardFilter.late, '').map((c) => c.name),
        ['Geç'],
      );
      expect(
        filterCards(deck(), CardFilter.soon, '').map((c) => c.name),
        ['Yakın'],
      );
    });

    test('by name or note, Turkish case-insensitive', () {
      expect(
        filterCards(deck(), CardFilter.all, 'ilaç').map((c) => c.name),
        ['İlaç'],
      );
      expect(
        filterCards(deck(), CardFilter.all, 'DOZ').map((c) => c.name),
        ['İlaç'],
      );
      expect(filterCards(deck(), CardFilter.late, 'ilaç'), isEmpty);
    });
  });

  test('a drag in a filtered grid keeps the hidden cards in place', () {
    expect(
      mergeSubsetOrder(['a', 'b', 'c', 'd', 'e'], ['d', 'b']),
      ['a', 'd', 'c', 'b', 'e'],
    );
    expect(mergeSubsetOrder(['a', 'b'], ['a', 'b']), ['a', 'b']);
  });

  group('reminders', () {
    final morning = DateTime(2026, 9, 18, 8);

    test('an archived card is never reminded', () {
      final plan = planReminders(
        [card('a', [2, 6, 10, 14], notify: true, archived: true)],
        morning,
      );
      expect(plan, isEmpty);
    });

    test("a card's own time wins over the global one", () {
      final plan = planReminders(
        [
          card('a', [2, 6, 10, 14], notify: true, remindAt: 20 * 60 + 15),
          card('b', [2, 6, 10, 14], notify: true),
        ],
        morning,
        hour: 9,
      );
      final a = plan.firstWhere((r) => r.cardId == 'a');
      final b = plan.firstWhere((r) => r.cardId == 'b');
      expect((a.at.hour, a.at.minute), (20, 15));
      expect((b.at.hour, b.at.minute), (9, 0));
    });
  });

  test('recordGaps: oldest first, capped to the newest', () {
    expect(recordGaps(card('a', [0, 3, 10])), [7, 3]);
    final many = card('a', [for (var i = 0; i < 20; i++) i * 2]);
    expect(recordGaps(many).length, gapChartMax);
    expect(recordGaps(card('a', [5])), isEmpty);
  });

  test('every template uses a real glyph and a positive rhythm', () {
    for (final t in cardTemplates) {
      expect(cardGlyphs.containsKey(t.icon), isTrue, reason: t.name);
      expect(t.every, greaterThan(0));
    }
  });
}
