/**
 * Calendar-day arithmetic in the device's local time zone.
 *
 * Records are persisted as `DateKey` strings (`YYYY-MM-DD`), never as offsets:
 * a card must tick over at local midnight, not 24h after the tap. Offsets are
 * derived at render time from "today".
 */

export type DateKey = string; // YYYY-MM-DD, local calendar day

export const DOW = ['Paz', 'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt'] as const;
export const MONTHS = [
  'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
  'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
] as const;
export const MONTHS_SHORT = [
  'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
  'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
] as const;

const pad = (n: number) => (n < 10 ? `0${n}` : String(n));

/** Local calendar day of a `Date` as a `DateKey`. */
export function toDateKey(d: Date): DateKey {
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
}

/** `DateKey` -> local `Date` at midnight. Parsed by parts to avoid UTC drift. */
export function fromDateKey(key: DateKey): Date {
  const [y, m, d] = key.split('-').map(Number);
  return new Date(y, m - 1, d);
}

export function todayKey(now: Date = new Date()): DateKey {
  return toDateKey(now);
}

/** `key` shifted by `n` whole days (negative goes back). */
export function shiftDays(key: DateKey, n: number): DateKey {
  const d = fromDateKey(key);
  d.setDate(d.getDate() + n);
  return toDateKey(d);
}

/**
 * Whole calendar days from `key` up to `reference`.
 * Both sides are normalised to local midnight first, so DST transitions
 * cannot produce a 0.96- or 1.04-day result.
 */
export function daysSince(key: DateKey, reference: DateKey): number {
  const a = fromDateKey(key).getTime();
  const b = fromDateKey(reference).getTime();
  return Math.round((b - a) / 86400000);
}

/** `18 Eylül`, with the year appended when it is not the reference year. */
export function formatDayMonth(key: DateKey, reference: DateKey): string {
  const d = fromDateKey(key);
  const sameYear = d.getFullYear() === fromDateKey(reference).getFullYear();
  return `${d.getDate()} ${MONTHS[d.getMonth()]}${sameYear ? '' : ` ${d.getFullYear()}`}`;
}

/** `18 Eylül 2026` — the pinned header date label. */
export function formatFullDate(key: DateKey): string {
  const d = fromDateKey(key);
  return `${d.getDate()} ${MONTHS[d.getMonth()]} ${d.getFullYear()}`;
}

/** `bugün` / `dün` / `3 gün önce` / `2 hafta önce` / `5 ay önce`. */
export function relativeLabel(offset: number): string {
  if (offset === 0) return 'bugün';
  if (offset === 1) return 'dün';
  if (offset < 7) return `${offset} gün önce`;
  if (offset < 60) return `${Math.round(offset / 7)} hafta önce`;
  return `${Math.round(offset / 30)} ay önce`;
}

/** Milliseconds from `now` until the next local midnight (never 0). */
export function msUntilMidnight(now: Date = new Date()): number {
  const next = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1, 0, 0, 0, 50);
  return Math.max(1000, next.getTime() - now.getTime());
}
