import 'dart:convert';

import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';
import 'package:ne_zaman/domain/card.dart';
import 'package:ne_zaman/domain/date.dart';
import 'package:ne_zaman/screens/home_screen.dart';
import 'package:ne_zaman/state/card_store.dart';
import 'package:ne_zaman/widgets/card_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A card `daysAgo` days old, with [gaps] behind it so it learns an interval.
Map<String, Object?> card(String id, String name, int daysAgo, List<int> gaps) {
  final today = todayKey();
  final offsets = <int>[daysAgo];
  var acc = daysAgo;
  for (final g in gaps) {
    acc += g;
    offsets.add(acc);
  }
  return {
    'id': id,
    'name': name,
    'recs': offsets.map((o) => shiftDays(today, -o)).toList(),
  };
}

Future<CardStore> pumpApp(
  WidgetTester tester,
  List<Map<String, Object?>> cards,
) async {
  SharedPreferences.setMockInitialValues({
    'nezaman.cards.v1': jsonEncode(cards),
  });
  final store = CardStore();
  await store.init();

  // A real phone-sized surface — the default 800x600 test window would make a
  // two-column phone layout overflow.
  tester.view.physicalSize = const Size(402 * 3, 874 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MediaQuery(
      // Animations off so pumpAndSettle is quick and deterministic.
      data: const MediaQueryData(size: Size(402, 874), disableAnimations: true),
      child: MaterialApp(
        home: Scaffold(body: HomeScreen(store: store)),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return store;
}

/// Runs [body] against a freshly pumped screen and always disposes the store.
///
/// The store keeps a timer alive until local midnight; the test framework
/// checks for pending timers *before* `addTearDown` callbacks run, so the
/// disposal has to happen inside the test body.
Future<void> runHome(
  WidgetTester tester,
  List<Map<String, Object?>> cards,
  Future<void> Function(CardStore store) body,
) async {
  final store = await pumpApp(tester, cards);
  try {
    await body(store);
  } finally {
    store.dispose();
  }
}

/// The grid is sorted by urgency, so a freshly created card is not
/// necessarily first — look it up by name.
Card byName(CardStore store, String name) =>
    store.cards.firstWhere((c) => c.name == name);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // typical 3, 11 days since -> overdue by 8.
  final lateCard = card('late', 'Spor salonuna gittim', 11, [3, 4, 2, 3]);
  // typical 4, 2 days since -> fresh.
  final freshCard = card('fresh', 'Bitkileri suladım', 2, [4, 3, 4]);

  testWidgets('shows every card, with the overdue count in the header', (
    tester,
  ) async {
    await runHome(tester, [lateCard, freshCard], (store) async {
      expect(find.byType(CardTile), findsNWidgets(2));
      expect(find.text('1 kart gecikti'), findsOneWidget);
      expect(find.text('8 gün geç'), findsOneWidget);
    });
  });

  testWidgets('the overdue pill filters down to the late cards and back', (
    tester,
  ) async {
    await runHome(tester, [lateCard, freshCard], (store) async {
      await tester.tap(find.text('1 kart gecikti'));
      await tester.pumpAndSettle();
      expect(find.byType(CardTile), findsOneWidget);
      expect(find.text('Spor salonuna gittim'), findsOneWidget);
      expect(find.text('Bitkileri suladım'), findsNothing);

      await tester.tap(find.text('1 kart gecikti'));
      await tester.pumpAndSettle();
      expect(find.byType(CardTile), findsNWidgets(2));
    });
  });

  testWidgets(
    'tapping a card opens the record sheet and picking a date records it',
    (tester) async {
      await runHome(tester, [lateCard, freshCard], (store) async {
        await tester.tap(find.text('Spor salonuna gittim'));
        await tester.pumpAndSettle();

        // The sheet is up, with the quick picks.
        expect(find.text('NE ZAMAN YAPTIN?'), findsOneWidget);
        expect(find.text('Bugün'), findsOneWidget);
        expect(find.text('DAHA GERİDEN SEÇ'), findsOneWidget);

        await tester.tap(find.text('Bugün'));
        await tester.pumpAndSettle();

        // Recorded today, so the card resets and the snackbar offers an undo.
        final recorded = store.cards.firstWhere((c) => c.id == 'late');
        expect(recorded.recs.first, todayKey());
        expect(
          find.textContaining('Spor salonuna gittim · bugün'),
          findsOneWidget,
        );
        expect(find.text('Geri al'), findsOneWidget);
      });
    },
  );

  testWidgets('undo restores the previous record list exactly', (tester) async {
    await runHome(tester, [lateCard, freshCard], (store) async {
      final before = [...store.cards.firstWhere((c) => c.id == 'late').recs];

      await tester.tap(find.text('Spor salonuna gittim'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bugün'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Geri al'));
      await tester.pumpAndSettle();

      expect(store.cards.firstWhere((c) => c.id == 'late').recs, before);
      expect(find.text('Geri al'), findsNothing);
    });
  });

  testWidgets('deleting asks first, then removes the card', (tester) async {
    await runHome(tester, [lateCard, freshCard], (store) async {
      await tester.tap(find.text('Bitkileri suladım'));
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Kartı sil'));
      await tester.pumpAndSettle();

      // The confirmation names the card and warns that it cannot be undone.
      expect(find.textContaining('silinsin mi?'), findsOneWidget);
      expect(find.textContaining('geri alınamaz'), findsOneWidget);

      await tester.tap(find.text('Vazgeç'));
      await tester.pumpAndSettle();
      expect(store.cards.any((c) => c.id == 'fresh'), isTrue);

      await tester.tap(find.bySemanticsLabel('Kartı sil'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sil'));
      await tester.pumpAndSettle();

      expect(store.cards.any((c) => c.id == 'fresh'), isFalse);
      expect(find.textContaining('silindi'), findsOneWidget);
    });
  });

  testWidgets(
    '"Bugün itibariyle ekle" creates a card with a capital first letter',
    (tester) async {
      await runHome(tester, [freshCard], (store) async {
        await tester.tap(find.text('Yeni kart'));
        await tester.pumpAndSettle();

        expect(find.text('Neyi takip edelim?'), findsOneWidget);
        // Tap a suggestion chip, which fills the lowercase sentence.
        await tester.tap(find.text('ilaç aldım'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Bugün itibariyle ekle'));
        await tester.pumpAndSettle();

        // Stored with Turkish casing: "i" becomes the dotted "İ".
        final created = byName(store, 'İlaç aldım');
        expect(created.recs, [todayKey()]);
      });
    },
  );

  testWidgets(
    '"Ekle ve tarih seç" creates a record-less card and opens the record sheet',
    (tester) async {
      await runHome(tester, [freshCard], (store) async {
        await tester.tap(find.text('Yeni kart'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('spor yaptım'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Ekle ve tarih seç'));
        await tester.pumpAndSettle();

        expect(byName(store, 'Spor yaptım').recs, isEmpty);
        // Handed straight over to the record sheet for the new card. The name
        // appears twice: once on the card behind the sheet, once as its title.
        expect(find.text('NE ZAMAN YAPTIN?'), findsOneWidget);
        expect(find.text('Spor yaptım'), findsNWidgets(2));
      });
    },
  );

  testWidgets('the timeline tab lists what actually happened', (tester) async {
    await runHome(tester, [lateCard, freshCard], (store) async {
      await tester.tap(find.text('Zaman tüneli'));
      await tester.pumpAndSettle();

      // Cards are gone; records are listed instead.
      expect(find.byType(CardTile), findsNothing);
      expect(find.text('2 gün önce'), findsOneWidget);
      // The header stays put.
      expect(find.text('En son ne zaman?'), findsOneWidget);
    });
  });

  testWidgets('a drag is remembered across a restart', (tester) async {
    await runHome(tester, [lateCard, freshCard], (store) async {
      // The overdue card sorts first on its own.
      expect(store.cards.map((c) => c.id), ['late', 'fresh']);

      store.reorder(['fresh', 'late']);
      await tester.pumpAndSettle();
      expect(store.cards.map((c) => c.id), ['fresh', 'late']);

      // A fresh store reading the same storage keeps the arrangement.
      final reopened = CardStore();
      await reopened.init();
      expect(reopened.cards.map((c) => c.id), ['fresh', 'late']);
      reopened.dispose();
    });
  });
}
