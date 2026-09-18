import { DateKey, shiftDays, todayKey } from '../domain/date';
import type { Card } from '../domain/types';

/**
 * First-launch content, matching the hifi mock card-for-card.
 *
 * Each entry is `[name, daysSinceLastTime, gapsGoingBackwards]`, exactly the
 * shape the prototype used. Offsets are resolved against the real first-launch
 * date so the tiers, rings and overdue flags read as designed on day one.
 *
 * Ship an empty array here instead if the product should start blank.
 */
const SEED: Array<[name: string, last: number, gaps: number[]]> = [
  ['Diş hekimine gittim', 214, [186, 192]],
  ['Spor salonuna gittim', 11, [3, 4, 2, 3]],
  ['Saçımı kestirdim', 46, [34, 38]],
  ['Çarşafları değiştirdim', 9, [11, 12, 10]],
  ['Anneme telefon ettim', 3, [4, 2, 5]],
  ['Bitkileri suladım', 5, [4, 3, 4]],
  ['Arabanın yağını değiştirdim', 121, [160, 175]],
  ['Buzdolabını temizledim', 28, [30, 26]],
  ['Yüzmeye gittim', 17, [9, 8, 11]],
];

export function seedCards(today: DateKey = todayKey()): Card[] {
  return SEED.map(([name, last, gaps]) => {
    const offsets = [last];
    let acc = last;
    for (const g of gaps) {
      acc += g;
      offsets.push(acc);
    }
    return {
      id: `seed-${name}`,
      name,
      recs: offsets.map((o) => shiftDays(today, -o)),
    };
  });
}
