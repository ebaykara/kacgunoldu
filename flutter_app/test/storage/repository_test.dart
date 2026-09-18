import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ne_zaman/domain/card.dart';
import 'package:ne_zaman/storage/repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CardRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = CardRepository();
  });

  group('manual order persistence', () {
    test('round-trips a saved arrangement', () async {
      await repository.saveManualOrder(['b', 'c', 'a']);
      expect(await repository.loadManualOrder(), ['b', 'c', 'a']);
    });

    test('is null before anything has ever been dragged', () async {
      expect(await repository.loadManualOrder(), isNull);
    });

    test('recovers from corrupted storage rather than throwing', () async {
      SharedPreferences.setMockInitialValues({'nezaman.order.v1': 'not json{{{'});
      expect(await repository.loadManualOrder(), isNull);
    });

    test('rejects a malformed shape instead of returning it verbatim', () async {
      SharedPreferences.setMockInitialValues({
        'nezaman.order.v1': jsonEncode([1, 2, 3]),
      });
      expect(await repository.loadManualOrder(), isNull);
    });
  });

  group('card persistence', () {
    test('seeds on first launch and writes the seed back', () async {
      final cards = await repository.loadCards();
      expect(cards, isNotEmpty);
      // The seed is now on disk, so a second read returns the same names.
      final again = await repository.loadCards();
      expect(again.map((c) => c.name), cards.map((c) => c.name));
    });

    test('round-trips cards', () async {
      const cards = [
        Card(id: 'a', name: 'Çamaşır yıkadım', recs: ['2026-09-18', '2026-09-10']),
      ];
      await repository.saveCards(cards);
      final loaded = await repository.loadCards();
      expect(loaded.length, 1);
      expect(loaded.first.name, 'Çamaşır yıkadım');
      expect(loaded.first.recs, ['2026-09-18', '2026-09-10']);
    });

    test('re-sorts records newest-first on read', () async {
      SharedPreferences.setMockInitialValues({
        'nezaman.cards.v1': jsonEncode([
          {
            'id': 'a',
            'name': 'x',
            'recs': ['2026-09-01', '2026-09-18', '2026-09-10'],
          }
        ]),
      });
      final loaded = await repository.loadCards();
      expect(loaded.first.recs, ['2026-09-18', '2026-09-10', '2026-09-01']);
    });

    test('drops a malformed card instead of losing the whole list', () async {
      SharedPreferences.setMockInitialValues({
        'nezaman.cards.v1': jsonEncode([
          {'id': 'ok', 'name': 'Geçerli', 'recs': <String>[]},
          {'id': 'bad', 'name': 'Bozuk', 'recs': ['not-a-date']},
          {'nope': true},
        ]),
      });
      final loaded = await repository.loadCards();
      expect(loaded.map((c) => c.id), ['ok']);
    });

    test('falls back to the seed when the payload is not a list', () async {
      SharedPreferences.setMockInitialValues({
        'nezaman.cards.v1': jsonEncode({'oops': true}),
      });
      final loaded = await repository.loadCards();
      expect(loaded, isNotEmpty);
    });
  });
}
