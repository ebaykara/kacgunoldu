import 'dart:convert';

import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';
import 'package:kac_gun_oldu/domain/card.dart';
import 'package:kac_gun_oldu/domain/date.dart';
import 'package:kac_gun_oldu/screens/home_screen.dart';
import 'package:kac_gun_oldu/services/reminders.dart';
import 'package:kac_gun_oldu/state/card_store.dart';
import 'package:kac_gun_oldu/theme/tokens.dart';
import 'package:kac_gun_oldu/widgets/card_row_tile.dart';
import 'package:kac_gun_oldu/widgets/card_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fake_reminders.dart';

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
  List<Map<String, Object?>> cards, {
  Reminders? reminders,
}) async {
  SharedPreferences.setMockInitialValues({
    'nezaman.cards.v1': jsonEncode(cards),
  });
  final store = CardStore(reminders: reminders);
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
  Future<void> Function(CardStore store) body, {
  Reminders? reminders,
}) async {
  final store = await pumpApp(tester, cards, reminders: reminders);
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

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.pumpAndSettle();
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

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
      expect(find.text('Kaç gün oldu?'), findsOneWidget);
      // Overdue is named by the header pill; on the card it is one status
      // line under the day count.
      expect(find.text('8 gün geçti'), findsOneWidget);
    });
  });

  testWidgets(
    'the overdue pill opens the overdue page, listing only late cards',
    (tester) async {
      await runHome(tester, [lateCard, freshCard], (store) async {
        await tester.tap(find.text('1 kart gecikti'));
        await tester.pumpAndSettle();

        expect(find.text('Gecikenler'), findsOneWidget);
        expect(find.text('1 kartın zamanı geçti'), findsOneWidget);
        expect(find.text('Spor salonuna gittim'), findsOneWidget);
        expect(find.text('Bitkileri suladım'), findsNothing);

        await tester.tap(find.bySemanticsLabel('Geri'));
        await tester.pumpAndSettle();
        expect(find.byType(CardTile), findsNWidgets(2));
      });
    },
  );

  testWidgets('swiping an overdue row records it and it leaves the list', (
    tester,
  ) async {
    await runHome(tester, [lateCard, freshCard], (store) async {
      await tester.tap(find.text('1 kart gecikti'));
      await tester.pumpAndSettle();

      await tester.drag(
        find.text('Spor salonuna gittim'),
        const Offset(400, 0),
      );
      await tester.pumpAndSettle();

      expect(
        store.cards.firstWhere((c) => c.id == 'late').recs.first,
        todayKey(),
      );
      expect(find.text('Her şey yerinde.'), findsOneWidget);
    });
  });

  testWidgets(
    'tapping a card opens its detail page; "Bugün yaptım" records it',
    (tester) async {
      await runHome(tester, [lateCard, freshCard], (store) async {
        await tester.tap(find.text('Spor salonuna gittim'));
        await tester.pumpAndSettle();

        expect(find.text('gün oldu'), findsOneWidget);
        expect(find.text('Son kayıt'), findsOneWidget);
        expect(find.text('Geçmiş'), findsOneWidget);

        await tester.tap(find.text('Bugün yaptım'));
        await tester.pumpAndSettle();

        // Recorded today: the page stays, flips its button and offers undo.
        final recorded = store.cards.firstWhere((c) => c.id == 'late');
        expect(recorded.recs.first, todayKey());
        expect(find.text('Bugün işaretlendi'), findsOneWidget);
        expect(
          find.textContaining('Spor salonuna gittim · bugün'),
          findsOneWidget,
        );
        expect(find.text('Geri al'), findsOneWidget);
      });
    },
  );

  testWidgets(
    '"Başka bir gün seç" opens the record sheet and picks a past day',
    (tester) async {
      await runHome(tester, [lateCard, freshCard], (store) async {
        await tester.tap(find.text('Spor salonuna gittim'));
        await tester.pumpAndSettle();
        await tapText(tester, 'Başka bir gün seç');

        expect(find.text('NE ZAMAN YAPTIN?'), findsOneWidget);
        expect(find.text('DAHA GERİDEN SEÇ'), findsOneWidget);
        expect(find.text('Takvimden seç'), findsOneWidget);

        await tester.tap(find.text('Dün'));
        await tester.pumpAndSettle();

        expect(
          store.cards.firstWhere((c) => c.id == 'late').recs.first,
          shiftDays(todayKey(), -1),
        );
      });
    },
  );

  testWidgets('undo restores the previous record list exactly', (tester) async {
    await runHome(tester, [lateCard, freshCard], (store) async {
      final before = [...store.cards.firstWhere((c) => c.id == 'late').recs];

      await tester.tap(find.text('Spor salonuna gittim'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bugün yaptım'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Geri al'));
      await tester.pumpAndSettle();

      expect(store.cards.firstWhere((c) => c.id == 'late').recs, before);
      expect(find.text('Geri al'), findsNothing);
      expect(find.text('Bugün yaptım'), findsOneWidget);
    });
  });

  testWidgets('a single record can be removed from the history, undoably', (
    tester,
  ) async {
    await runHome(tester, [lateCard, freshCard], (store) async {
      final before = [...store.cards.firstWhere((c) => c.id == 'fresh').recs];

      await tester.tap(find.text('Bitkileri suladım'));
      await tester.pumpAndSettle();
      // The date shows twice — "Son kayıt" and the newest history row.
      await tester.ensureVisible(find.text(formatFullDate(before.first)).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text(formatFullDate(before.first)).last);
      await tester.pumpAndSettle();
      await tapText(tester, 'Bu kaydı sil');

      expect(
        store.cards.firstWhere((c) => c.id == 'fresh').recs,
        before.skip(1).toList(),
      );
      expect(find.textContaining('kaydı silindi'), findsOneWidget);

      await tester.tap(find.text('Geri al'));
      await tester.pumpAndSettle();
      expect(store.cards.firstWhere((c) => c.id == 'fresh').recs, before);
    });
  });

  testWidgets('deleting asks first, then removes the card', (tester) async {
    await runHome(tester, [lateCard, freshCard], (store) async {
      await tester.tap(find.text('Bitkileri suladım'));
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Kart seçenekleri'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kartı sil'));
      await tester.pumpAndSettle();

      // The confirmation names the card and warns that it cannot be undone.
      expect(find.textContaining('silinsin mi?'), findsOneWidget);
      expect(find.textContaining('geri alınamaz'), findsOneWidget);

      await tester.tap(find.text('Vazgeç'));
      await tester.pumpAndSettle();
      expect(store.cards.any((c) => c.id == 'fresh'), isTrue);

      await tester.tap(find.text('Kartı sil'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sil'));
      await tester.pumpAndSettle();

      // Back on the grid, with the card gone.
      expect(store.cards.any((c) => c.id == 'fresh'), isFalse);
      expect(find.byType(CardTile), findsOneWidget);
      expect(find.textContaining('silindi'), findsOneWidget);
    });
  });

  testWidgets('a new card is recorded today, with a capital first letter', (
    tester,
  ) async {
    await runHome(tester, [freshCard], (store) async {
      await tester.tap(find.text('Yeni kart'));
      await tester.pumpAndSettle();

      expect(find.text('Ne yaptın?'), findsOneWidget);
      expect(find.text('Ne sıklıkla tekrarlıyorsun?'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'ilaç aldım');
      await tester.pumpAndSettle();
      // The glyph follows the name as it is typed.
      expect(find.byIcon(Icons.medication_outlined), findsOneWidget);

      await tapText(tester, 'Kartı oluştur');

      // Stored with Turkish casing: "i" becomes the dotted "İ".
      final created = byName(store, 'İlaç aldım');
      expect(created.recs, [todayKey()]);
      expect(created.every, isNull);
      expect(created.created, todayKey());
      expect(find.text('“İlaç aldım” eklendi'), findsOneWidget);
    });
  });

  testWidgets('a declared rhythm and "Henüz yapmadım" are saved as chosen', (
    tester,
  ) async {
    await runHome(tester, [freshCard], (store) async {
      await tester.tap(find.text('Yeni kart'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'banyoyu temizledim');
      await tester.pumpAndSettle();

      await tapText(tester, 'Haftada bir');
      await tapText(tester, 'Bugün');
      await tapText(tester, 'Henüz yapmadım');
      await tapText(tester, 'Kartı oluştur');

      final created = byName(store, 'Banyoyu temizledim');
      expect(created.recs, isEmpty);
      expect(created.every, 7);
    });
  });

  testWidgets('editing renames a card and changes its rhythm', (tester) async {
    await runHome(tester, [lateCard, freshCard], (store) async {
      await tester.tap(find.text('Bitkileri suladım'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Kart seçenekleri'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Düzenle'));
      await tester.pumpAndSettle();

      expect(find.text('Kartı düzenle'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Çiçekleri suladım');
      await tapText(tester, '2 günde bir');
      await tapText(tester, 'Kaydet');

      final edited = store.cards.firstWhere((c) => c.id == 'fresh');
      expect(edited.name, 'Çiçekleri suladım');
      expect(edited.every, 2);
      // Back on the detail page, which follows the rename.
      expect(find.text('Çiçekleri suladım'), findsOneWidget);
    });
  });

  testWidgets('the timeline tab lists every record and filters by range', (
    tester,
  ) async {
    await runHome(tester, [lateCard, freshCard], (store) async {
      await tester.tap(find.text('Zaman tüneli'));
      await tester.pumpAndSettle();

      // Cards are gone; records are listed instead, grouped by month.
      expect(find.byType(CardTile), findsNothing);
      expect(find.text('Tümü'), findsOneWidget);
      expect(find.text('2 gün'), findsOneWidget);
      final t = DateTime.now();
      expect(find.text('${months[t.month - 1]} ${t.year}'), findsOneWidget);

      // The last week: only the plants (2 and 6 days ago), not the gym (11).
      await tester.tap(find.text('Hafta'));
      await tester.pumpAndSettle();
      expect(find.text('Bitkileri suladım'), findsNWidgets(2));
      expect(find.text('Spor salonuna gittim'), findsNothing);

      // A row opens its card.
      await tester.tap(find.text('2 gün'));
      await tester.pumpAndSettle();
      expect(find.text('Geçmiş'), findsOneWidget);
    });
  });

  testWidgets(
    'no cards shows the guided start; a suggestion prefills the form',
    (tester) async {
      await runHome(tester, [], (store) async {
        expect(find.text('İlk kartını oluştur'), findsOneWidget);
        expect(find.text('Önerilen kartlar'), findsOneWidget);

        await tapText(tester, 'Saçımı kestirdim');
        expect(find.text('Yeni kart'), findsOneWidget);
        await tapText(tester, 'Kartı oluştur');

        final created = byName(store, 'Saçımı kestirdim');
        expect(created.icon, 'scissors');
        expect(created.every, 30);
        expect(find.byType(CardTile), findsOneWidget);
      });
    },
  );

  testWidgets('the profile shows the stats and saves a name', (tester) async {
    await runHome(tester, [lateCard, freshCard], (store) async {
      await tester.tap(find.bySemanticsLabel('Profil'));
      await tester.pumpAndSettle();

      expect(find.text('Toplam kart'), findsOneWidget);
      expect(find.text('Toplam kayıt'), findsOneWidget);
      expect(find.text('En düzenli yaptığın'), findsOneWidget);
      expect(find.text('En uzun süredir yapmadığın'), findsOneWidget);

      await tester.tap(find.text('Adını ekle'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Eyüp Baykara');
      await tester.tap(find.text('Kaydet'));
      await tester.pumpAndSettle();

      expect(store.profile.name, 'Eyüp Baykara');
      expect(find.text('EB'), findsOneWidget);
    });
  });

  testWidgets('settings reset the dragged order back to urgency', (
    tester,
  ) async {
    await runHome(tester, [lateCard, freshCard], (store) async {
      store.reorder(['fresh', 'late']);
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Profil'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Ayarlar'));
      await tester.pumpAndSettle();
      await tapText(tester, 'Sıralamayı sıfırla');

      expect(store.hasManualOrder, isFalse);
      expect(store.cards.map((c) => c.id), ['late', 'fresh']);
    });
  });

  testWidgets('the new-card form can mark a card for reminders', (tester) async {
    final fake = FakeReminders();
    await runHome(tester, [freshCard], (store) async {
      await tester.tap(find.text('Yeni kart'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'anneme telefon ettim');
      await tester.pumpAndSettle();
      await tapText(tester, 'Haftada bir');

      expect(find.text('Bana hatırlat'), findsWidgets);
      expect(find.textContaining('saat 09:00 civarı'), findsOneWidget);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(fake.permissionAsks, 1);

      await tapText(tester, 'Kartı oluştur');

      final created = byName(store, 'Anneme telefon ettim');
      expect(created.notify, isTrue);
      expect(created.every, 7);
      // Recorded today, weekly: due in 7 days at 09:00, plus the follow-up.
      final mine = fake.plan.where((r) => r.cardId == created.id).toList();
      expect(mine.length, 2);
      expect(mine.first.title, 'Anneme telefon ettim');
      expect(mine.first.body, contains('7 gün'));
      expect(mine.first.body, endsWith(' Hedefin haftada bir.'));
    }, reminders: fake);
  });

  testWidgets('a refused permission leaves the switch off and says why', (tester) async {
    final fake = FakeReminders(granted: false);
    await runHome(tester, [freshCard], (store) async {
      await tester.tap(find.text('Yeni kart'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'ilaç aldım');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
      expect(find.textContaining('Bildirim izni kapalı'), findsOneWidget);
    }, reminders: fake);
  });

  testWidgets('reminders can be switched from the card menu', (tester) async {
    final fake = FakeReminders();
    await runHome(tester, [lateCard, freshCard], (store) async {
      await tester.tap(find.text('Bitkileri suladım'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Kart seçenekleri'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bana hatırlat'));
      await tester.pumpAndSettle();

      expect(store.byId('fresh')!.notify, isTrue);
      expect(fake.plan.any((r) => r.cardId == 'fresh'), isTrue);

      await tester.tap(find.bySemanticsLabel('Kart seçenekleri'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hatırlatmayı kapat'));
      await tester.pumpAndSettle();
      expect(store.byId('fresh')!.notify, isFalse);
      expect(fake.plan, isEmpty);
    }, reminders: fake);
  });

  testWidgets('tapping a notification opens that card', (tester) async {
    final fake = FakeReminders();
    await runHome(tester, [lateCard, freshCard], (store) async {
      expect(find.text('Geçmiş'), findsNothing);
      fake.tapController.add('fresh');
      await tester.pumpAndSettle();
      expect(find.text('Geçmiş'), findsOneWidget);
      expect(find.text('Bitkileri suladım'), findsWidgets);
      expect(store.openCardRequest.value, isNull);
    }, reminders: fake);
  });

  testWidgets('a notification that launched the app opens its card', (tester) async {
    await runHome(tester, [lateCard, freshCard], (store) async {
      expect(find.text('Geçmiş'), findsOneWidget);
    }, reminders: FakeReminders(launchedWith: 'late'));
  });

  testWidgets('settings: reminder time and the test notification', (tester) async {
    final fake = FakeReminders();
    await runHome(tester, [lateCard, freshCard], (store) async {
      await tester.tap(find.bySemanticsLabel('Profil'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Ayarlar'));
      await tester.pumpAndSettle();

      expect(find.text('09:00'), findsOneWidget);
      store.setReminderTime(20, 30);
      await tester.pumpAndSettle();
      expect(find.text('20:30'), findsOneWidget);

      await tapText(tester, 'Test bildirimi gönder');
      expect(fake.shown.length, 1);
      expect(fake.shown.first.$2, contains('11 gün'));
    }, reminders: fake);
  });

  testWidgets('with nothing overdue there is no status pill at all', (tester) async {
    await runHome(tester, [freshCard], (store) async {
      expect(find.textContaining('gecikti'), findsNothing);
      expect(find.text('her şey yerinde'), findsNothing);
      expect(find.text('Kaç gün oldu?'), findsOneWidget);
    });
  });

  testWidgets('the layout button switches grid and list, and the choice sticks', (
    tester,
  ) async {
    await runHome(tester, [lateCard, freshCard], (store) async {
      expect(find.byType(CardRowTile), findsNothing);
      expect(find.byType(CardTile), findsNWidgets(2));

      await tester.tap(find.bySemanticsLabel('Liste görünümü'));
      await tester.pumpAndSettle();
      expect(store.layout, CardLayout.list);
      expect(find.byType(CardRowTile), findsNWidgets(2));
      expect(find.byType(CardTile), findsNothing);
      // Same numbers, one row each, full width.
      expect(find.text('gün oldu'), findsNWidgets(2));
      final width = tester.getSize(find.byType(CardRowTile).first).width;
      expect(width, greaterThan(300));

      // A row still opens its card.
      await tester.tap(find.text('Bitkileri suladım'));
      await tester.pumpAndSettle();
      expect(find.text('Geçmiş'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Geri'));
      await tester.pumpAndSettle();

      // Remembered across a restart.
      final reopened = CardStore();
      await reopened.init();
      expect(reopened.layout, CardLayout.list);
      reopened.dispose();

      await tester.tap(find.bySemanticsLabel('Izgara görünümü'));
      await tester.pumpAndSettle();
      expect(find.byType(CardTile), findsNWidgets(2));
      expect(store.layout, CardLayout.grid);
    });
  });

  testWidgets('a theme picked in settings recolours the app', (tester) async {
    await runHome(tester, [lateCard, freshCard], (store) async {
      try {
        await tester.tap(find.bySemanticsLabel('Profil'));
        await tester.pumpAndSettle();
        await tester.tap(find.bySemanticsLabel('Ayarlar'));
        await tester.pumpAndSettle();
        await tapText(tester, 'Tema');
        await tester.tap(find.bySemanticsLabel('Gece teması'));
        await tester.pumpAndSettle();

        expect(store.themeId, 'gece');
        expect(AppColor.surface, paletteById('gece').surface);

        // Back on the grid, the overdue card is drawn in the new primary.
        for (var i = 0; i < 3; i++) {
          await tester.tap(find.bySemanticsLabel('Geri').first);
          await tester.pumpAndSettle();
        }
        final tile = find.descendant(
          of: find.byType(CardTile).first,
          matching: find.byType(Container),
        );
        final colors = tester
            .widgetList<Container>(tile)
            .map((c) => c.color)
            .whereType<Color>();
        expect(colors, contains(paletteById('gece').primary));
      } finally {
        AppColor.current = kiremit;
      }
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

  testWidgets('a note can be written on a record and shows in the history', (
    tester,
  ) async {
    await runHome(tester, [lateCard, freshCard], (store) async {
      final newest = store.byId('fresh')!.recs.first;
      await tester.tap(find.text('Bitkileri suladım'));
      await tester.pumpAndSettle();
      // Three gaps: the "Aralıklar" chart is there.
      expect(find.text('Aralıklar'), findsOneWidget);

      await tester.ensureVisible(find.text(formatFullDate(newest)).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text(formatFullDate(newest)).last);
      await tester.pumpAndSettle();
      await tapText(tester, 'Not ekle');
      await tester.enterText(find.byType(TextField), 'yarım bardak');
      await tapText(tester, 'Kaydet');

      expect(store.byId('fresh')!.notes, {newest: 'yarım bardak'});
      expect(find.text('yarım bardak'), findsOneWidget);
    });
  });

  testWidgets('archiving takes a card off the grid; the archive brings it back', (
    tester,
  ) async {
    await runHome(tester, [lateCard, freshCard], (store) async {
      await tester.tap(find.text('Spor salonuna gittim'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Kart seçenekleri'));
      await tester.pumpAndSettle();
      await tapText(tester, 'Arşivle');

      // Back on the grid: one card, no overdue pill, a way into the archive.
      expect(find.byType(CardTile), findsOneWidget);
      expect(find.text('1 kart gecikti'), findsNothing);
      await tapText(tester, 'Arşiv (1)');
      expect(find.text('Spor salonuna gittim'), findsOneWidget);

      await tapText(tester, 'Spor salonuna gittim');
      await tapText(tester, 'Arşivden çıkar');
      expect(store.byId('late')!.archived, isFalse);
      expect(store.cards.length, 2);
    });
  });

  testWidgets('with enough cards, search and the filter chips narrow the grid', (
    tester,
  ) async {
    final many = [
      lateCard,
      freshCard,
      for (var i = 0; i < 4; i++) card('c$i', 'Kart $i', 1, [5, 5]),
    ];
    await runHome(tester, many, (store) async {
      expect(find.text('Kartlarda ara'), findsOneWidget);

      await tapText(tester, 'Gecikenler');
      expect(find.byType(CardTile), findsOneWidget);
      expect(find.text('Spor salonuna gittim'), findsOneWidget);

      await tapText(tester, 'Tümü');
      await tester.enterText(find.byType(TextField), 'bitki');
      await tester.pumpAndSettle();
      expect(find.byType(CardTile), findsOneWidget);
      expect(find.text('Bitkileri suladım'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'yok böyle');
      await tester.pumpAndSettle();
      expect(find.text('Eşleşen kart yok.'), findsOneWidget);
    });
  });

  testWidgets('few cards: no search bar', (tester) async {
    await runHome(tester, [lateCard, freshCard], (store) async {
      expect(find.text('Kartlarda ara'), findsNothing);
    });
  });

  testWidgets('a ready-made card fills the form', (tester) async {
    await runHome(tester, [freshCard], (store) async {
      await tester.tap(find.text('Yeni kart'));
      await tester.pumpAndSettle();
      expect(find.text('Hazır kartlar'), findsOneWidget);

      await tapText(tester, 'Diş fırçamı değiştirdim');
      expect(find.text('Hazır kartlar'), findsNothing);
      await tapText(tester, 'Kartı oluştur');

      final created = byName(store, 'Diş fırçamı değiştirdim');
      expect(created.every, 90);
      expect(created.icon, 'tooth');
    });
  });
}
