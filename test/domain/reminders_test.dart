import 'package:flutter_test/flutter_test.dart';
import 'package:kac_gun_oldu/domain/card.dart';
import 'package:kac_gun_oldu/domain/date.dart';
import 'package:kac_gun_oldu/domain/reminders.dart';

const today = '2026-09-18';

/// 08:00 that day — before the 09:00 reminder time.
final morning = DateTime(2026, 9, 18, 8);

Card card(
  String name,
  List<int> offsets, {
  bool notify = true,
  int? every,
}) =>
    Card(
      id: name,
      name: name,
      recs: offsets.map((o) => shiftDays(today, -o)).toList(),
      notify: notify,
      every: every,
    );

void main() {
  group('planReminders', () {
    test('only cards marked for reminders get any', () {
      final plan = planReminders([
        card('a', [2, 6, 10, 14], notify: false),
        card('b', [2, 6, 10, 14]),
      ], morning);
      expect(plan.map((r) => r.cardId).toSet(), {'b'});
    });

    test('schedules the due day at the chosen time, then a follow-up', () {
      // typical 4, last 2 days ago -> due 2026-09-20.
      final plan = planReminders([card('Bitkileri suladım', [2, 6, 10, 14])], morning);
      expect(plan.length, 2);
      expect(plan[0].at, DateTime(2026, 9, 20, 9));
      expect(plan[0].title, 'Bitkileri suladım');
      expect(
        plan[0].body,
        '4 gündür yapmadın, sırası geldi. Genelde 4 günde bir yapıyorsun.',
      );
      expect(plan[1].at, DateTime(2026, 9, 22, 9));
      expect(
        plan[1].body,
        '6 gün oldu, 2 gün geçti. Yaptıysan dokun, işaretle.',
      );
    });

    test('a declared rhythm is named in the message and works on one record', () {
      final plan = planReminders([card('Saçımı kestirdim', [3], every: 30)], morning);
      expect(plan.first.at, DateTime(2026, 10, 15, 9));
      expect(plan.first.body, '30 gündür yapmadın, sırası geldi. Hedefin ayda bir.');
    });

    test('honours the reminder time', () {
      final plan = planReminders(
        [card('a', [2, 6, 10, 14])],
        morning,
        hour: 20,
        minute: 30,
      );
      expect(plan.first.at, DateTime(2026, 9, 20, 20, 30));
    });

    test('a card due today after the reminder time still gets today\'s', () {
      // typical 4, last 4 days ago -> due today.
      final plan = planReminders([card('a', [4, 8, 12, 16])], morning);
      expect(plan.first.at, DateTime(2026, 9, 18, 9));
      // ...but not once 09:00 has passed: the follow-up remains.
      final later = planReminders([card('a', [4, 8, 12, 16])], DateTime(2026, 9, 18, 10));
      expect(later.length, 1);
      expect(later.first.at, DateTime(2026, 9, 20, 9));
    });

    test('a card that has been late for a long time gets a single nudge', () {
      // typical 3, last 11 days ago: due 8 days ago, follow-up long gone.
      final plan = planReminders([card('Spor salonuna gittim', [11, 14, 18, 20, 23])], morning);
      expect(plan.length, 1);
      expect(plan.first.at, DateTime(2026, 9, 18, 9));
      expect(plan.first.body, '11 gün oldu, 8 gün geçti. Yaptıysan dokun, işaretle.');

      // After 09:00 the nudge moves to tomorrow morning, with tomorrow's count.
      final evening = planReminders(
        [card('Spor salonuna gittim', [11, 14, 18, 20, 23])],
        DateTime(2026, 9, 18, 21),
      );
      expect(evening.first.at, DateTime(2026, 9, 19, 9));
      expect(evening.first.body, '12 gün oldu, 9 gün geçti. Yaptıysan dokun, işaretle.');
    });

    test('cards with no rhythm yet or no records are skipped', () {
      final plan = planReminders([
        card('two records', [3, 10]),
        card('none', []),
      ], morning);
      expect(plan, isEmpty);
    });

    test('ids are stable per card and distinct per slot', () {
      expect(reminderId('abc', 0), reminderId('abc', 0));
      expect(reminderId('abc', 0), isNot(reminderId('abc', 1)));
      expect(reminderId('abc', 0), isNot(reminderId('abd', 0)));
      expect(reminderId('abc', 2), lessThan(0x7FFFFFFF));
    });

    test('formats the time of day', () {
      expect(timeLabel(9, 0), '09:00');
      expect(timeLabel(20, 5), '20:05');
    });
  });

  test('the notify flag round-trips and stays out of JSON when off', () {
    const on = Card(id: 'a', name: 'A', recs: [], notify: true);
    expect(Card.tryFromJson(on.toJson())!.notify, isTrue);
    const off = Card(id: 'a', name: 'A', recs: []);
    expect(off.toJson().containsKey('notify'), isFalse);
    expect(Card.tryFromJson(off.toJson())!.notify, isFalse);
  });
}
