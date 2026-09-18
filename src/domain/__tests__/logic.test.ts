import { daysSince, msUntilMidnight, relativeLabel, shiftDays, toDateKey } from '../date';
import { statsFor, typicalInterval } from '../logic';
import type { Card } from '../types';

const TODAY = '2026-09-18';

/** Build a card whose records sit `offsets` days before TODAY. */
const card = (name: string, offsets: number[]): Card => ({
  id: name,
  name,
  recs: offsets.map((o) => shiftDays(TODAY, -o)),
});

describe('typicalInterval', () => {
  it('is null under three records — one gap is not a rhythm', () => {
    expect(typicalInterval([])).toBeNull();
    expect(typicalInterval([5])).toBeNull();
    expect(typicalInterval([5, 12])).toBeNull();
  });

  it('is the middle gap for an odd count', () => {
    // gaps: 3, 10, 4 -> sorted 3, 4, 10
    expect(typicalInterval([0, 3, 13, 17])).toBe(4);
  });

  it('rounds the mean of the middle two for an even count', () => {
    // gaps: 3, 4, 2, 3 -> sorted 2, 3, 3, 4 -> (3 + 3) / 2
    expect(typicalInterval([11, 14, 18, 20, 23])).toBe(3);
    // gaps: 186, 192 -> (186 + 192) / 2 = 189
    expect(typicalInterval([214, 400, 592])).toBe(189);
  });
});

describe('overdue rule', () => {
  it('never flags a card that has not learned an interval yet', () => {
    const s = statsFor(card('yeni', [400, 800]), TODAY);
    expect(s.typical).toBeNull();
    expect(s.late).toBe(false);
    expect(s.ringLabel).toBe('yeni');
  });

  it('flags a card past typical * 1.25 + 1', () => {
    // typical 3; threshold 4.75; 11 days since
    const s = statsFor(card('Spor salonuna gittim', [11, 14, 18, 20, 23]), TODAY);
    expect(s.typical).toBe(3);
    expect(s.late).toBe(true);
    expect(s.tier).toBe('late');
  });

  it('gives short-interval cards a one-day grace', () => {
    // typical 4; threshold 6. Five days late is still calm, seven is not.
    expect(statsFor(card('Bitkileri suladım', [5, 9, 12, 16]), TODAY).late).toBe(false);
    expect(statsFor(card('Bitkileri suladım', [7, 11, 14, 18]), TODAY).late).toBe(true);
  });

  it('does not flag exactly at the threshold', () => {
    // typical 36; threshold 46; 46 days since -> not late, but `soon`
    const s = statsFor(card('Saçımı kestirdim', [46, 80, 118]), TODAY);
    expect(s.typical).toBe(36);
    expect(s.late).toBe(false);
    expect(s.tier).toBe('soon');
  });
});

describe('a card with no records yet', () => {
  // Reachable through "Ekle ve tarih seç", which creates the card before the
  // date is picked.
  const empty: Card = { id: 'empty', name: 'yeni kart', recs: [] };

  it('renders without a last-record date', () => {
    const s = statsFor(empty, TODAY);
    expect(s.days).toBe(0);
    expect(s.typical).toBeNull();
    expect(s.late).toBe(false);
    expect(s.meta).toBe('Henüz işaretlenmedi');
    expect(s.remaining).toBeNull();
    expect(s.ringLabel).toBe('yeni');
    expect(s.pct).toBe(3);
  });
});

describe('tier and ring', () => {
  it('walks late -> soon -> calm -> fresh as the ratio falls', () => {
    const tierFor = (days: number) => statsFor(card('x', [days, days + 10, days + 20, days + 30]), TODAY).tier;
    expect(tierFor(20)).toBe('late'); // ratio 2.0
    expect(tierFor(11)).toBe('soon'); // ratio 1.1
    expect(tierFor(7)).toBe('calm'); // ratio 0.7
    expect(tierFor(4)).toBe('fresh'); // ratio 0.4
  });

  it('clamps the ring between 3% and 100%', () => {
    expect(statsFor(card('x', [0, 10, 20, 30]), TODAY).pct).toBe(3);
    expect(statsFor(card('x', [60, 70, 80, 90]), TODAY).pct).toBe(100);
  });

  it('reads the ring as time left, not as a ratio', () => {
    // typical 4, two days since -> two days of the interval left
    const soon = statsFor(card('x', [2, 6, 9, 13]), TODAY);
    expect(soon.remaining).toBe(2);
    expect(soon.ringLabel).toBe('2 gün');
    expect(soon.ringHint).toBe('her zamanki aralığa 2 gün kaldı');

    // typical 4, four days since -> due today
    const due = statsFor(card('x', [4, 8, 11, 15]), TODAY);
    expect(due.ringLabel).toBe('bugün');

    // typical 3, eleven days since -> eight days past the usual interval
    const late = statsFor(card('x', [11, 14, 18, 20, 23]), TODAY);
    expect(late.remaining).toBe(-8);
    expect(late.ringLabel).toBe('+8 gün');
    expect(late.ringHint).toBe('her zamanki aralığı 8 gün aştı');
  });
});

describe('meta line', () => {
  it('keeps the same shape whether a card is late or not', () => {
    // The overdue amount lives in the ring (+8 gün), not here — repeating it
    // in a second phrasing was the confusing part.
    const s = statsFor(card('Spor salonuna gittim', [11, 14, 18, 20, 23]), TODAY);
    expect(s.late).toBe(true);
    expect(s.meta).toBe('7 Eylül ~3 günde bir');
  });

  it('reads "Bugün yapıldı" the day it is recorded', () => {
    expect(statsFor(card('x', [0, 4, 8, 12]), TODAY).meta).toBe('Bugün yapıldı');
  });

  it('pairs the date with the learned interval', () => {
    expect(statsFor(card('x', [5, 9, 12, 16]), TODAY).meta).toBe('13 Eylül ~4 günde bir');
  });

  it('appends the year once the record leaves the current one', () => {
    expect(statsFor(card('x', [300, 700]), TODAY).meta).toBe('22 Kasım 2025');
  });
});

describe('calendar-day arithmetic', () => {
  it('counts whole calendar days, not 24h blocks', () => {
    expect(daysSince('2026-09-17', '2026-09-18')).toBe(1);
    expect(daysSince('2026-09-18', '2026-09-18')).toBe(0);
    expect(daysSince('2025-12-31', '2026-01-01')).toBe(1);
  });

  it('survives a spring-forward DST boundary', () => {
    // Europe/Istanbul has no DST today, so assert the normalisation directly:
    // both ends are pinned to local midnight before subtracting.
    expect(daysSince('2026-03-28', '2026-03-29')).toBe(1);
    expect(daysSince('2026-10-24', '2026-10-25')).toBe(1);
  });

  it('rolls a card over at midnight rather than 24h after the tap', () => {
    const justBeforeMidnight = new Date(2026, 8, 18, 23, 59, 30);
    const justAfterMidnight = new Date(2026, 8, 19, 0, 0, 30);
    expect(toDateKey(justBeforeMidnight)).toBe('2026-09-18');
    expect(toDateKey(justAfterMidnight)).toBe('2026-09-19');

    // A card recorded at 23:59 reads "1 gün" thirty seconds later.
    expect(daysSince('2026-09-18', toDateKey(justAfterMidnight))).toBe(1);
  });

  it('schedules the next rollover inside the coming day', () => {
    const ms = msUntilMidnight(new Date(2026, 8, 18, 23, 59, 0));
    expect(ms).toBeGreaterThan(0);
    expect(ms).toBeLessThanOrEqual(24 * 60 * 60 * 1000);
  });
});

describe('relativeLabel', () => {
  it('matches the copy in the handoff', () => {
    expect(relativeLabel(0)).toBe('bugün');
    expect(relativeLabel(1)).toBe('dün');
    expect(relativeLabel(6)).toBe('6 gün önce');
    expect(relativeLabel(14)).toBe('2 hafta önce');
    expect(relativeLabel(59)).toBe('8 hafta önce');
    expect(relativeLabel(90)).toBe('3 ay önce');
  });
});
