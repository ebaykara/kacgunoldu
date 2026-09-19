import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kac_gun_oldu/domain/card.dart';
import 'package:kac_gun_oldu/domain/date.dart';
import 'package:kac_gun_oldu/domain/reminders.dart';
import 'package:kac_gun_oldu/state/card_store.dart';
import 'package:kac_gun_oldu/storage/repository.dart';
import 'package:kac_gun_oldu/theme/tokens.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fake_reminders.dart';

/// Runs [body] with a store over [cards] and always disposes it — the
/// midnight timer must not outlive the test.
Future<void> withStore(
  List<Map<String, Object?>> cards,
  Future<void> Function(CardStore store) body,
) async {
  SharedPreferences.setMockInitialValues({
    'nezaman.cards.v1': jsonEncode(cards),
  });
  final store = CardStore();
  await store.init();
  try {
    await body(store);
  } finally {
    store.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final t = todayKey();
  final plants = {
    'id': 'p',
    'name': 'Bitkileri suladım',
    'recs': [shiftDays(t, -2), shiftDays(t, -6), shiftDays(t, -9)],
  };

  test('removeRecord drops one day and undo brings it back', () async {
    await withStore([plants], (store) async {
      final before = [...store.byId('p')!.recs];
      store.removeRecord('p', before[1]);
      expect(store.byId('p')!.recs, [before[0], before[2]]);
      expect(store.snack!.undoable, isTrue);
      store.undo();
      expect(store.byId('p')!.recs, before);
    });
  });

  test('moveRecord keeps the list newest-first', () async {
    await withStore([plants], (store) async {
      final recs = store.byId('p')!.recs;
      store.moveRecord('p', recs[2], shiftDays(t, -1));
      expect(store.byId('p')!.recs, [
        shiftDays(t, -1),
        shiftDays(t, -2),
        shiftDays(t, -6),
      ]);
    });
  });

  test(
    'updateCard renames with Turkish casing and can clear the rhythm',
    () async {
      await withStore([plants], (store) async {
        store.updateCard('p', name: 'ıhlamur suladım', icon: 'plant', every: 3);
        expect(store.byId('p')!.name, 'Ihlamur suladım');
        expect(store.byId('p')!.every, 3);
        store.updateCard('p', name: 'Ihlamur suladım', icon: null, every: null);
        expect(store.byId('p')!.every, isNull);
        expect(store.byId('p')!.icon, isNull);
      });
    },
  );

  test('a backup restores cards, order and profile exactly', () async {
    String backup = '';
    await withStore([plants], (store) async {
      store.addCard('çay demledim', 0, every: 1);
      store.updateProfile(const Profile(name: 'Eyüp', handle: '@gezenti'));
      store.reorder(store.cards.map((c) => c.id).toList().reversed.toList());
      backup = store.exportJson();
    });
    await withStore([], (store) async {
      expect(store.importJson(backup), 2);
      // The saved drag order comes back with it: tea first, as reordered.
      expect(store.cards.map((c) => c.name), [
        'Çay demledim',
        'Bitkileri suladım',
      ]);
      expect(store.cards.first.every, 1);
      expect(store.profile.name, 'Eyüp');
      expect(store.profile.handle, 'gezenti');
      expect(store.hasManualOrder, isTrue);
    });
  });

  test('a malformed backup changes nothing', () async {
    await withStore([plants], (store) async {
      expect(store.importJson('not json'), isNull);
      expect(
        store.importJson(
          jsonEncode({
            'cards': [
              {'id': 1},
            ],
          }),
        ),
        isNull,
      );
      expect(store.cards.length, 1);
    });
  });

  test(
    'clearAll empties everything; loadSamples adds only what is missing',
    () async {
      await withStore([plants], (store) async {
        store.clearAll();
        expect(store.cards, isEmpty);
        final added = store.loadSamples();
        expect(added, greaterThan(0));
        expect(store.loadSamples(), 0);
      });
    },
  );

  test('the profile survives a restart', () async {
    await withStore([plants], (store) async {
      store.updateProfile(const Profile(name: 'Eyüp Baykara'));
      final reopened = CardStore();
      await reopened.init();
      expect(reopened.profile.name, 'Eyüp Baykara');
      reopened.dispose();
    });
  });

  test('the chosen theme applies at once and survives a restart', () async {
    await withStore([plants], (store) async {
      expect(store.themeId, 'kiremit');
      store.setTheme('okyanus');
      expect(AppColor.primary, paletteById('okyanus').primary);

      final reopened = CardStore();
      AppColor.current = kiremit;
      await reopened.init();
      expect(reopened.themeId, 'okyanus');
      reopened.dispose();
      AppColor.current = kiremit;
    });
  });

  group('reminders', () {
    test('every change re-plans; recording moves the due day', () async {
      final fake = FakeReminders();
      SharedPreferences.setMockInitialValues({
        'nezaman.cards.v1': jsonEncode([
          {
            'id': 'p',
            'name': 'Bitkileri suladım',
            'notify': true,
            'recs': [shiftDays(t, -6), shiftDays(t, -10), shiftDays(t, -14), shiftDays(t, -18)],
          },
        ]),
      });
      final store = CardStore(reminders: fake);
      await store.init();
      try {
        // typical 4, last 6 days ago: long overdue -> one nudge.
        await Future<void>.delayed(Duration.zero);
        expect(fake.plan.length, 1);
        // A "still not done" one — the follow-up before 09:00 today, the
        // nudge after. Its wording is picked per day, so not asserted.
        expect([reminderId('p', 1), reminderId('p', 2)], contains(fake.plan.first.id));

        store.record('p', 0);
        await Future<void>.delayed(Duration.zero);
        // Done today: due in 4 days, plus the follow-up.
        expect(fake.plan.length, 2);
        expect(fake.plan.first.at.difference(DateTime.now()).inDays, inInclusiveRange(3, 4));

        store.deleteCard('p');
        await Future<void>.delayed(Duration.zero);
        expect(fake.plan, isEmpty);
      } finally {
        store.dispose();
      }
    });

    test('turning a card on needs permission; refusal changes nothing', () async {
      final fake = FakeReminders(granted: false);
      SharedPreferences.setMockInitialValues({'nezaman.cards.v1': jsonEncode([plants])});
      final store = CardStore(reminders: fake);
      await store.init();
      try {
        expect(await store.setCardNotify('p', true), isFalse);
        expect(store.byId('p')!.notify, isFalse);
        expect(store.snack!.message, contains('izni kapalı'));

        fake.granted = true;
        expect(await store.setCardNotify('p', true), isTrue);
        expect(store.byId('p')!.notify, isTrue);
        expect(store.reminderCount, 1);
        // Turning off needs no permission.
        fake.permissionAsks = 0;
        expect(await store.setCardNotify('p', false), isTrue);
        expect(fake.permissionAsks, 0);
      } finally {
        store.dispose();
      }
    });

    test('the reminder time is remembered and used for the plan', () async {
      final fake = FakeReminders();
      SharedPreferences.setMockInitialValues({
        'nezaman.cards.v1': jsonEncode([
          {...plants, 'notify': true},
        ]),
      });
      final store = CardStore(reminders: fake);
      await store.init();
      store.setReminderTime(21, 15);
      await Future<void>.delayed(Duration.zero);
      expect(fake.plan.every((r) => r.at.hour == 21 && r.at.minute == 15), isTrue);
      store.dispose();

      final reopened = CardStore(reminders: fake);
      await reopened.init();
      expect((reopened.reminderHour, reopened.reminderMinute), (21, 15));
      reopened.dispose();
    });

    test('a backup keeps which cards are marked', () async {
      final fake = FakeReminders();
      SharedPreferences.setMockInitialValues({
        'nezaman.cards.v1': jsonEncode([
          {...plants, 'notify': true},
        ]),
      });
      final store = CardStore(reminders: fake);
      await store.init();
      final backup = store.exportJson();
      store.clearAll();
      expect(store.importJson(backup), 1);
      expect(store.byId('p')!.notify, isTrue);
      store.dispose();
    });
  });

  group('notes', () {
    test('a note follows its record: removed with it, moved with it, undone with it', () async {
      await withStore([plants], (store) async {
        final recs = [...store.byId('p')!.recs];
        store.setNote('p', recs[1], '  yarım bardak  ');
        expect(store.byId('p')!.notes, {recs[1]: 'yarım bardak'});

        store.moveRecord('p', recs[1], shiftDays(t, -4));
        expect(store.byId('p')!.notes, {shiftDays(t, -4): 'yarım bardak'});
        store.undo();
        expect(store.byId('p')!.notes, {recs[1]: 'yarım bardak'});

        store.removeRecord('p', recs[1]);
        expect(store.byId('p')!.notes, isEmpty);
        store.undo();
        expect(store.byId('p')!.notes, {recs[1]: 'yarım bardak'});

        store.setNote('p', recs[1], '');
        expect(store.byId('p')!.notes, isEmpty);
      });
    });

    test('notes are kept across a restart', () async {
      await withStore([plants], (store) async {
        final day = store.byId('p')!.recs.first;
        store.setNote('p', day, 'gübre');
        await Future<void>.delayed(Duration.zero);
        final reopened = CardStore();
        await reopened.init();
        expect(reopened.byId('p')!.notes, {day: 'gübre'});
        reopened.dispose();
      });
    });
  });

  test('an archived card leaves the grid and the reminders, keeps its records', () async {
    final fake = FakeReminders();
    SharedPreferences.setMockInitialValues({
      'nezaman.cards.v1': jsonEncode([
        {
          ...plants,
          'notify': true,
          'recs': [shiftDays(t, -1), shiftDays(t, -5), shiftDays(t, -9)],
        },
      ]),
    });
    final store = CardStore(reminders: fake);
    await store.init();
    try {
      await Future<void>.delayed(Duration.zero);
      expect(fake.plan, isNotEmpty);

      store.setArchived('p', true);
      await Future<void>.delayed(Duration.zero);
      expect(store.cards, isEmpty);
      expect(store.archivedCards.single.recs.length, 3);
      expect(store.hasAnyCards, isTrue);
      expect(store.reminderCount, 0);
      expect(fake.plan, isEmpty);

      store.setArchived('p', false);
      await Future<void>.delayed(Duration.zero);
      expect(store.cards.single.id, 'p');
      expect(fake.plan, isNotEmpty);
    } finally {
      store.dispose();
    }
  });

  test('a shared card is added once, as a fresh copy', () async {
    await withStore([plants], (store) async {
      final shared = Card(
        id: '',
        name: 'yağ değişimi',
        recs: [shiftDays(t, -30)],
        every: 180,
        notify: true,
      );
      final id = store.importSharedCard(shared)!;
      final added = store.byId(id)!;
      expect(added.name, 'Yağ değişimi');
      expect(added.every, 180);
      expect(added.notify, isFalse);
      expect(added.created, t);
      expect(store.cards.length, 2);

      expect(store.importSharedCard(shared), isNull);
      expect(store.cards.length, 2);
    });
  });
}
