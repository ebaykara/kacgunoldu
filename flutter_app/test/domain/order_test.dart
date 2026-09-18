import 'package:flutter_test/flutter_test.dart';
import 'package:ne_zaman/domain/card.dart';
import 'package:ne_zaman/domain/date.dart';
import 'package:ne_zaman/domain/order.dart';

const today = '2026-09-18';

Card card(String id, List<int> offsets) => Card(
      id: id,
      name: id,
      recs: offsets.map((o) => shiftDays(today, -o)).toList(),
    );

List<String> ids(List<Card> cards) => cards.map((c) => c.id).toList();

void main() {
  group('applyOrder — with no saved arrangement', () {
    test('falls back to urgency: overdue first, then soonest-due', () {
      final cards = [
        card('fresh', [2, 12, 22, 32]), // ratio 0.2
        card('late', [11, 14, 18, 20, 23]), // typical 3, days 11 -> late
        card('calm', [20, 30, 40, 50]), // ratio 0.67
      ];
      expect(ids(applyOrder(cards, null, today)), ['late', 'calm', 'fresh']);
    });
  });

  group('applyOrder — with a saved arrangement', () {
    test('respects the exact saved sequence, ignoring urgency', () {
      final cards = [
        card('a', [11, 14, 18, 20, 23]), // would sort first automatically
        card('b', [2, 12, 22, 32]),
        card('c', [20, 30, 40, 50]),
      ];
      // The person dragged the most-urgent card to the bottom on purpose.
      expect(ids(applyOrder(cards, ['b', 'c', 'a'], today)), ['b', 'c', 'a']);
    });

    test('puts a card missing from the saved order at the front', () {
      // "new" was created after the last drag, so it has no saved position —
      // matches where a freshly created card has always appeared.
      final cards = [card('a', [5]), card('b', [9]), card('new', [0])];
      expect(ids(applyOrder(cards, ['a', 'b'], today)), ['new', 'a', 'b']);
    });

    test('is stable when two cards are both missing from the saved order', () {
      final cards = [card('older', [5]), card('newer', [1]), card('a', [9])];
      expect(ids(applyOrder(cards, ['a'], today)), ['older', 'newer', 'a']);
    });

    test('ignores ids in the saved order that no longer exist', () {
      // "gone" was deleted; its ghost entry must not shift anyone else.
      final cards = [card('a', [5]), card('b', [9])];
      expect(ids(applyOrder(cards, ['gone', 'b', 'a'], today)), ['b', 'a']);
    });

    test('treats an empty saved order the same as none — falls back to urgency', () {
      final cards = [card('late', [11, 14, 18, 20, 23]), card('fresh', [2, 12, 22, 32])];
      expect(ids(applyOrder(cards, [], today)), ['late', 'fresh']);
    });

    test('keeps a full saved order across every card', () {
      final cards = [
        card('a', [1]),
        card('b', [2]),
        card('c', [3]),
        card('d', [4]),
      ];
      final shuffled = ['d', 'b', 'a', 'c'];
      expect(ids(applyOrder(cards, shuffled, today)), shuffled);
    });
  });
}
