import 'card.dart';
import 'date.dart';
import 'frequency.dart';
import 'logic.dart';
import 'reminder_copy.dart';

/// One notification to hand to the operating system.
class Reminder {
  const Reminder({
    required this.id,
    required this.cardId,
    required this.at,
    required this.title,
    required this.body,
  });

  final int id;
  final String cardId;

  /// Local wall-clock time it should appear.
  final DateTime at;
  final String title;
  final String body;
}

/// Default time of day reminders arrive.
const defaultReminderHour = 9;
const defaultReminderMinute = 0;

/// `09:00`
String timeLabel(int hour, int minute) =>
    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

/// Days after the due day the "still not done" follow-up arrives.
const followUpAfterDays = 2;

/// Stable notification id for a card and a slot (0 = due, 1 = follow-up,
/// 2 = nudge). FNV-1a, so the same card always maps to the same ids.
int reminderId(String cardId, int slot) {
  var h = 0x811c9dc5;
  for (final unit in cardId.codeUnits) {
    h ^= unit;
    h = (h * 0x01000193) & 0xFFFFFFFF;
  }
  return (h % 100000000) * 10 + slot;
}

/// Everything that should be pending right now, derived from the cards —
/// nothing about notifications is stored except the "notify" flag and the
/// time of day.
///
/// Per marked card that has a rhythm (declared or learned):
///  * **due** — on the day the usual interval runs out, at [hour]:[minute];
///  * **follow-up** — [followUpAfterDays] days later, if it still isn't done;
///  * **nudge** — if both of those are already in the past (a card that has
///    been late for a while), one for the next [hour]:[minute].
/// Recording the card moves its due day, so the plan is rebuilt after every
/// change and the old notifications are replaced.
List<Reminder> planReminders(
  List<Card> cards,
  DateTime now, {
  int hour = defaultReminderHour,
  int minute = defaultReminderMinute,
}) {
  final today = todayKey(now);
  DateTime at(DateKey key) {
    final d = fromDateKey(key);
    return DateTime(d.year, d.month, d.day, hour, minute);
  }

  final out = <Reminder>[];
  for (final card in cards) {
    if (!card.notify || card.recs.isEmpty) continue;
    final typical = statsFor(card, today).typical;
    if (typical == null) continue;

    final last = card.recs.first;
    final due = shiftDays(last, typical);
    // Only a rhythm the user chose is worth naming; a learned one is noise.
    final goal = card.every != null
        ? ' Hedefin ${frequencyLabel(card.every!).toLowerCase()}.'
        : '';

    var scheduled = false;

    final dueAt = at(due);
    if (dueAt.isAfter(now)) {
      final n = daysSince(last, due);
      out.add(Reminder(
        id: reminderId(card.id, 0),
        cardId: card.id,
        at: dueAt,
        title: card.name,
        body: dueBody(card.name, n, seed: '${card.id}|$due|0') + goal,
      ));
      scheduled = true;
    }

    final followKey = shiftDays(due, followUpAfterDays);
    final followAt = at(followKey);
    if (followAt.isAfter(now)) {
      out.add(Reminder(
        id: reminderId(card.id, 1),
        cardId: card.id,
        at: followAt,
        title: card.name,
        body: lateBody(
          card.name,
          daysSince(last, followKey),
          followUpAfterDays,
          seed: '${card.id}|$due|1',
        ),
      ));
      scheduled = true;
    }

    if (!scheduled) {
      final nudgeKey = at(today).isAfter(now) ? today : shiftDays(today, 1);
      final n = daysSince(last, nudgeKey);
      out.add(Reminder(
        id: reminderId(card.id, 2),
        cardId: card.id,
        at: at(nudgeKey),
        title: card.name,
        body: lateBody(card.name, n, n - typical, seed: '${card.id}|$nudgeKey|2'),
      ));
    }
  }
  out.sort((a, b) => a.at.compareTo(b.at));
  return out;
}
