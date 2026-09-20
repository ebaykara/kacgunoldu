import 'dart:convert';

import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';
import 'package:kac_gun_oldu/domain/card.dart';
import 'package:kac_gun_oldu/domain/date.dart';
import 'package:kac_gun_oldu/domain/frequency.dart';
import 'package:kac_gun_oldu/domain/logic.dart';
import 'package:kac_gun_oldu/domain/reminder_copy.dart';
import 'package:kac_gun_oldu/domain/reminders.dart';
import 'package:kac_gun_oldu/domain/text.dart';
import 'package:kac_gun_oldu/l10n/strings.dart';
import 'package:kac_gun_oldu/l10n/strings_en.dart';
import 'package:kac_gun_oldu/l10n/strings_tr.dart';
import 'package:kac_gun_oldu/screens/home_screen.dart';
import 'package:kac_gun_oldu/services/home_widgets.dart';
import 'package:kac_gun_oldu/state/card_store.dart';
import 'package:kac_gun_oldu/storage/seed.dart';
import 'package:kac_gun_oldu/theme/tokens.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Back to the suite's default (Turkish) whatever a test switched to.
void _resetLang() => applyLang(AppLang.system, device: const Locale('tr'));

Card _card(String name, int daysAgo, List<int> gaps, {int? every}) {
  final today = todayKey();
  final offsets = <int>[daysAgo];
  var acc = daysAgo;
  for (final g in gaps) {
    acc += g;
    offsets.add(acc);
  }
  return Card(
    id: 'c-$name',
    name: name,
    every: every,
    recs: offsets.map((o) => shiftDays(today, -o)).toList(),
  );
}

void main() {
  tearDown(_resetLang);

  group('which language is in use', () {
    test('system follows the device, falling back to Turkish', () {
      applyLang(AppLang.system, device: const Locale('en'));
      expect(resolvedLang, AppLang.en);
      applyLang(AppLang.system, device: const Locale('en', 'GB'));
      expect(resolvedLang, AppLang.en);
      applyLang(AppLang.system, device: const Locale('tr'));
      expect(resolvedLang, AppLang.tr);
      // Anything else lands on Turkish, the same order supportedLocales has.
      applyLang(AppLang.system, device: const Locale('de'));
      expect(resolvedLang, AppLang.tr);
    });

    test('a chosen language wins over the device', () {
      applyLang(AppLang.tr, device: const Locale('en'));
      expect(resolvedLang, AppLang.tr);
      expect(S.didItToday, 'Bugün yaptım');

      applyLang(AppLang.en, device: const Locale('tr'));
      expect(resolvedLang, AppLang.en);
      expect(S.didItToday, 'Did it today');
    });

    test('MaterialApp gets a locale only when one was chosen', () {
      applyLang(AppLang.system, device: const Locale('en'));
      expect(appLocale, isNull);
      applyLang(AppLang.en);
      expect(appLocale, const Locale('en'));
      applyLang(AppLang.tr);
      expect(appLocale, const Locale('tr'));
    });

    test('an unknown saved id falls back to following the phone', () {
      expect(AppLang.fromId(null), AppLang.system);
      expect(AppLang.fromId('nope'), AppLang.system);
      expect(AppLang.fromId('en'), AppLang.en);
      expect(AppLang.fromId('tr'), AppLang.tr);
    });
  });

  group('the two languages stay in step', () {
    const tr = TrStrings();
    const en = EnStrings();

    test('the same frequency presets, in the same order', () {
      expect(
        en.frequencyPresets.map((p) => p.$1),
        tr.frequencyPresets.map((p) => p.$1),
      );
    });

    test('a glyph label for every glyph', () {
      expect(en.glyphLabels.keys.toSet(), tr.glyphLabels.keys.toSet());
    });

    test('the same number of ready-made cards, suggestions and samples', () {
      expect(en.templates.length, tr.templates.length);
      expect(en.suggestions.length, tr.suggestions.length);
      expect(en.seedCards.length, tr.seedCards.length);
      // The rhythms are the product's, not the language's.
      expect(
        en.templates.map((t) => t.$3),
        tr.templates.map((t) => t.$3),
      );
    });

    test('four legend rows and twelve months either way', () {
      expect(en.legendRows.length, 4);
      expect(tr.legendRows.length, 4);
      for (final s in [tr, en]) {
        expect(s.months.length, 12);
        expect(s.monthsShort.length, 12);
        expect(s.dow.length, 7);
      }
    });

    test('the home screen widgets get the same keys', () {
      expect(en.widgetStrings.keys.toSet(), tr.widgetStrings.keys.toSet());
      // Every counted line keeps its placeholder.
      for (final key in ['late', 'daysLeft', 'daysOver']) {
        expect(en.widgetStrings[key], contains('{n}'));
        expect(tr.widgetStrings[key], contains('{n}'));
      }
    });

    test('every reminder topic has a due line and a late line', () {
      for (final topic in ReminderTopic.values) {
        for (final s in [tr, en]) {
          final copy = s.reminderCopy[topic];
          expect(copy, isNotNull, reason: '$topic missing in ${s.lang}');
          expect(copy!.$1, isNotEmpty);
          expect(copy.$2, isNotEmpty);
        }
      }
    });

    test('the ring label and its suffix agree, so the ring can split them', () {
      for (final s in [tr, en]) {
        expect(s.ringDays(4).endsWith(s.ringUnitSuffix), isTrue);
        expect(s.ringOver(8).endsWith(s.ringUnitSuffix), isTrue);
        expect(s.ringNew.endsWith(s.ringUnitSuffix), isFalse);
        expect(s.ringToday.endsWith(s.ringUnitSuffix), isFalse);
      }
    });
  });

  group('English dates and derived text', () {
    setUp(() => applyLang(AppLang.en));

    test('the month leads, and the year only when it is another one', () {
      expect(formatDayMonth('2026-09-18', '2026-01-01'), 'September 18');
      expect(formatDayMonth('2025-09-18', '2026-01-01'), 'September 18, 2025');
      expect(formatFullDate('2026-09-18'), 'September 18, 2026');
    });

    test('relative labels', () {
      expect(relativeLabel(0), 'today');
      expect(relativeLabel(1), 'yesterday');
      expect(relativeLabel(3), '3 days ago');
      expect(relativeLabel(14), '2 weeks ago');
      expect(relativeLabel(90), '3 months ago');
    });

    test('a declared rhythm reads as a preset, a custom one spells it out', () {
      expect(frequencyLabel(7), 'Weekly');
      expect(frequencyLabel(10), 'Every 10 days');
    });

    test('the meta line keeps the interval unbreakable', () {
      final card = _card('Watered the plants', 2, [4, 3, 4]);
      final meta = statsFor(card, todayKey()).meta;
      expect(meta, contains('~every 4 days'));
      expect(meta, isNot(contains('~every 4 days')));
    });

    test('the status line and the ring speak English', () {
      final stats = statsFor(_card('Got a haircut', 40, [], every: 30), todayKey());
      expect(stats.ringLabel, '+10 days');
      expect(stats.ringHint, '10 days past the usual interval');
    });

    test('casing has no Turkish dotted I', () {
      expect(S.upper('it is'), 'IT IS');
      expect(S.capitalize('iron'), 'Iron');
      // Turkish keeps its own rules.
      applyLang(AppLang.tr);
      expect(S.upper('ilaç'), 'İLAÇ');
      expect(capitalizeTr('ilaç'), 'İlaç');
    });
  });

  group('matching is language-agnostic', () {
    test('an English card name finds its topic and glyph', () {
      applyLang(AppLang.en);
      expect(topicOf('Watered the plants'), ReminderTopic.plant);
      expect(topicOf('Got a haircut'), ReminderTopic.hair);
      expect(topicOf('Went to the gym'), ReminderTopic.gym);
      expect(topicOf('Paid the rent'), ReminderTopic.bill);
      expect(topicOf('Took my vitamins'), ReminderTopic.pill);
    });

    test('a Turkish card name still works with the interface in English', () {
      applyLang(AppLang.en);
      expect(topicOf('Saçımı kestirdim'), ReminderTopic.hair);
      expect(topicOf('Bitkileri suladım'), ReminderTopic.plant);
      expect(topicOf('İlaç aldım'), ReminderTopic.pill);
    });

    test('and an English name with the interface in Turkish', () {
      applyLang(AppLang.tr);
      expect(topicOf('Called my mum'), ReminderTopic.family);
      expect(topicOf('Cleaned the fridge'), ReminderTopic.fridge);
    });
  });

  group('reminders follow the language', () {
    test('an English card gets an English body and goal line', () {
      applyLang(AppLang.en);
      final card = Card(
        id: 'x',
        name: 'Watered the plants',
        every: 7,
        notify: true,
        recs: [shiftDays(todayKey(), -1)],
      );
      final plan = planReminders(
        [card],
        DateTime.now(),
        hour: 9,
        minute: 0,
      );
      expect(plan, isNotEmpty);
      final due = plan.first;
      expect(due.title, 'Watered the plants');
      expect(due.body, endsWith(' Your goal: weekly.'));
      // The joke lines are the English ones, not the Turkish.
      expect(due.body, isNot(contains('gün')));
    });
  });

  group('the app in English', () {
    testWidgets('the home screen, the grid and the tabs are translated',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'nezaman.lang.v1': 'en',
        'nezaman.cards.v1': jsonEncode([
          {
            'id': 'a',
            'name': 'Watered the plants',
            'every': 3,
            'recs': [shiftDays(todayKey(), -9)],
          },
        ]),
      });
      final store = CardStore();
      await store.init();

      tester.view.physicalSize = const Size(402 * 3, 874 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(402, 874),
            disableAnimations: true,
          ),
          child: MaterialApp(home: Scaffold(body: HomeScreen(store: store))),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('How many days?'), findsOneWidget);
      expect(find.text('days ago'), findsWidgets);
      expect(find.text('Cards'), findsWidgets);
      expect(find.text('Timeline'), findsWidgets);
      expect(find.text('1 card overdue'), findsOneWidget);
      expect(find.textContaining('gün'), findsNothing);

      // Disposed here rather than in a tear-down: the midnight timer has to
      // be cancelled before the framework checks for pending ones.
      store.dispose();
    });

    testWidgets('a language picked in settings sticks and reaches the store',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final store = CardStore();
      await store.init();

      expect(store.lang, AppLang.system);
      expect(resolvedLang, AppLang.tr);

      store.setLang(AppLang.en);
      expect(S.didItToday, 'Did it today');

      // Saved, and read back by a fresh store.
      final again = CardStore();
      await again.init();
      expect(again.lang, AppLang.en);
      expect(resolvedLang, AppLang.en);

      store.dispose();
      again.dispose();
    });
  });

  test('the widget snapshot carries the language with it', () {
    applyLang(AppLang.en);
    final card = _card('Watered the plants', 9, [], every: 3);
    final json = jsonDecode(widgetSnapshot([card], todayKey()))
        as Map<String, Object?>;
    final strings = json['strings']! as Map<String, Object?>;
    expect(strings['unitDays'], 'days ago');
    expect(strings['daysOver'], '{n} days over');
    expect(strings['title'], 'How many days?');
  });

  test('sample cards keep one id per card, whatever the language', () {
    applyLang(AppLang.tr);
    final tr = seedCards('2026-09-18').map((c) => c.id).toList();
    applyLang(AppLang.en);
    final en = seedCards('2026-09-18');
    expect(en.map((c) => c.id).toList(), tr);
    // The name still follows the language.
    expect(en.first.name, 'Went to the dentist');
  });

  test('every theme has its own name in both languages', () {
    for (final s in [const TrStrings(), const EnStrings()]) {
      final names = palettes.map((p) => s.themeName(p.id)).toList();
      expect(names.toSet().length, palettes.length, reason: '${s.lang}: $names');
    }
  });

  test('CSV headers follow the language', () {
    applyLang(AppLang.en);
    expect(const EnStrings().csvHeader, 'Card,Date,Note');
    applyLang(AppLang.tr);
    expect(const TrStrings().csvHeader, 'Kart,Tarih,Not');
  });
}
