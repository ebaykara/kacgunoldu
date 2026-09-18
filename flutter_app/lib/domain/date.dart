/// Calendar-day arithmetic in the device's local time zone.
///
/// Records are persisted as `DateKey` strings (`YYYY-MM-DD`), never as offsets:
/// a card must tick over at local midnight, not 24h after the tap. Offsets are
/// derived at render time from "today".
library;

/// `YYYY-MM-DD`, a local calendar day.
typedef DateKey = String;

const dow = ['Paz', 'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt'];

const months = [
  'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
  'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
];

const monthsShort = [
  'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
  'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
];

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
  return '${d.day} ${months[d.month - 1]}${sameYear ? '' : ' ${d.year}'}';
}

/// `18 Eylül 2026` — the pinned header date label.
String formatFullDate(DateKey key) {
  final d = fromDateKey(key);
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

/// `bugün` / `dün` / `3 gün önce` / `2 hafta önce` / `5 ay önce`.
String relativeLabel(int offset) {
  if (offset == 0) return 'bugün';
  if (offset == 1) return 'dün';
  if (offset < 7) return '$offset gün önce';
  if (offset < 60) return '${(offset / 7).round()} hafta önce';
  return '${(offset / 30).round()} ay önce';
}

/// Time from [now] until the next local midnight (never under a second).
Duration untilMidnight([DateTime? now]) {
  final at = now ?? DateTime.now();
  final next = DateTime(at.year, at.month, at.day + 1, 0, 0, 0, 50);
  final ms = next.difference(at).inMilliseconds;
  return Duration(milliseconds: ms < 1000 ? 1000 : ms);
}
