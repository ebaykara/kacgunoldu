/// Calendar-day arithmetic in the device's local time zone.
///
/// Records are persisted as `DateKey` strings (`YYYY-MM-DD`), never as offsets:
/// a card must tick over at local midnight, not 24h after the tap. Offsets are
/// derived at render time from "today".
library;

import '../l10n/strings.dart';

/// `YYYY-MM-DD`, a local calendar day.
typedef DateKey = String;

/// Sunday first — index with `dow[d.weekday % 7]`, since Dart's `weekday`
/// starts the week on Monday.
List<String> get dow => S.dow;

List<String> get months => S.months;

List<String> get monthsShort => S.monthsShort;

String _pad(int n) => n < 10 ? '0$n' : '$n';

/// Local calendar day of a [DateTime] as a [DateKey].
DateKey toDateKey(DateTime d) => '${d.year}-${_pad(d.month)}-${_pad(d.day)}';

/// [DateKey] -> local `DateTime` at midnight. Parsed by parts to avoid UTC drift.
DateTime fromDateKey(DateKey key) {
  final parts = key.split('-');
  return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
}

DateKey todayKey([DateTime? now]) => toDateKey(now ?? DateTime.now());

/// [key] shifted by [n] whole days (negative goes back).
DateKey shiftDays(DateKey key, int n) {
  final d = fromDateKey(key);
  return toDateKey(DateTime(d.year, d.month, d.day + n));
}

/// Whole calendar days from [key] up to [reference].
///
/// Both sides are normalised to local midnight first, so a DST transition
/// cannot produce a 0.96- or 1.04-day result. The rounding on the millisecond
/// difference is what absorbs the 23h/25h days.
int daysSince(DateKey key, DateKey reference) {
  final a = fromDateKey(key).millisecondsSinceEpoch;
  final b = fromDateKey(reference).millisecondsSinceEpoch;
  return ((b - a) / 86400000).round();
}

/// `18 Eylül`, with the year appended when it is not the reference year.
String formatDayMonth(DateKey key, DateKey reference) {
  final d = fromDateKey(key);
  final sameYear = d.year == fromDateKey(reference).year;
  return S.dayMonth(d.day, d.month, year: sameYear ? null : d.year);
}

/// `18 Eylül 2026` — the pinned header date label.
String formatFullDate(DateKey key) {
  final d = fromDateKey(key);
  return S.fullDate(d.day, d.month, d.year);
}

/// `bugün` / `dün` / `3 gün önce` / `2 hafta önce` / `5 ay önce`.
String relativeLabel(int offset) {
  if (offset == 0) return S.relToday;
  if (offset == 1) return S.relYesterday;
  if (offset < 7) return S.relDaysAgo(offset);
  if (offset < 60) return S.relWeeksAgo((offset / 7).round());
  return S.relMonthsAgo((offset / 30).round());
}

/// Time from [now] until the next local midnight (never under a second).
Duration untilMidnight([DateTime? now]) {
  final at = now ?? DateTime.now();
  final next = DateTime(at.year, at.month, at.day + 1, 0, 0, 0, 50);
  final ms = next.difference(at).inMilliseconds;
  return Duration(milliseconds: ms < 1000 ? 1000 : ms);
}
