import { color } from '../theme/tokens';
import {
  DateKey,
  daysSince,
  formatDayMonth,
} from './date';
import type { Card, Tier } from './types';

/** Palette per tier — the card's whole colour identity. */
export const TIERS: Record<Tier, { bg: string; ink: string; ring: string; track: string; tag: string }> = {
  fresh: { bg: color.tertiaryContainer, ink: color.onTertiaryContainer, ring: color.tertiary, track: 'rgba(31,42,20,0.13)', tag: color.tertiary },
  calm: { bg: color.surfaceBright, ink: color.onSurface, ring: color.primaryDim, track: 'rgba(36,31,27,0.10)', tag: color.primaryDim },
  soon: { bg: color.primaryContainer, ink: color.onPrimaryContainer, ring: color.primary, track: 'rgba(58,12,0,0.14)', tag: color.primary },
  late: { bg: color.primary, ink: color.onPrimary, ring: color.ringOnPrimary, track: 'rgba(255,243,234,0.28)', tag: 'rgba(255,243,234,0.22)' },
};

/** Day offsets of a card's records, ascending in age (`[0]` = most recent). */
export function offsetsOf(card: Card, today: DateKey): number[] {
  return card.recs.map((r) => daysSince(r, today));
}

/**
 * Median gap between consecutive records.
 *
 * `null` under three records (fewer than two gaps) — one gap is not a rhythm,
 * and a card without a typical interval can never be flagged overdue.
 */
export function typicalInterval(offsets: number[]): number | null {
  const gaps: number[] = [];
  for (let i = 0; i < offsets.length - 1; i++) gaps.push(offsets[i + 1] - offsets[i]);
  if (gaps.length < 2) return null;
  const s = gaps.slice().sort((a, b) => a - b);
  return s.length % 2
    ? s[(s.length - 1) / 2]
    : Math.round((s[s.length / 2 - 1] + s[s.length / 2]) / 2);
}

export type CardStats = {
  /** Days since the most recent record. */
  days: number;
  /** Median interval, or `null` while the card is still learning. */
  typical: number | null;
  /** `days / typical`, or a gentle `days / 30` ramp while learning. */
  ratio: number;
  late: boolean;
  tier: Tier;
  /** Ring fill, 3–100%. */
  pct: number;
  /**
   * Days left before this is due again — negative once it is past due,
   * `null` while the card is still learning its interval.
   */
  remaining: number | null;
  /** Text inside the ring: `4 gün`, `bugün`, `+8 gün`, or `yeni`. */
  ringLabel: string;
  /** The ring, spelled out for screen readers. */
  ringHint: string;
  /** The card's meta line. */
  meta: string;
};

/**
 * Everything the UI needs about a card, derived fresh from `recs` + today.
 *
 * Overdue is `days > typical * 1.25 + 1`: the `+1` keeps short-interval cards
 * (water the plants every 3 days) from flagging on a single late day.
 */
export function statsFor(card: Card, today: DateKey): CardStats {
  const offsets = offsetsOf(card, today);
  const days = offsets.length ? offsets[0] : 0;
  const typical = typicalInterval(offsets);
  const ratio = typical ? days / typical : Math.min(0.95, days / 30);
  const late = typical !== null && days > typical * 1.25 + 1;
  const tier: Tier = late ? 'late' : ratio > 0.95 ? 'soon' : ratio < 0.5 ? 'fresh' : 'calm';
  const pct = Math.max(3, Math.min(100, Math.round(ratio * 100)));

  // Always the same shape — last date + the learned interval — whether the
  // card is late or not. The overdue amount already lives in the ring
  // (`+8 gün`); repeating it here in a different phrasing was confusing.
  //
  // No "·" between the two halves — it read as a stray line. A plain space
  // is enough of a break, and a non-breaking space keeps "günde bir" from
  // splitting across a wrap (the Text itself is also capped at one line).
  const lastKey: DateKey | undefined = card.recs[0];
  const meta =
    lastKey === undefined
      ? 'Henüz işaretlenmedi'
      : days === 0
        ? 'Bugün yapıldı'
        : typical
          ? `${formatDayMonth(lastKey, today)} ~${typical} günde bir`
          : formatDayMonth(lastKey, today);

  /**
   * The ring answers one question: how long until this is due again?
   *
   * `4 gün` means four days of the usual interval are left, `bugün` means it
   * is due today, `+8 gün` means it is eight days past the usual interval, and
   * `yeni` means the card has not learned an interval yet. The arc is the same
   * value drawn as progress through the interval.
   */
  const remaining = typical === null ? null : typical - days;
  const ringLabel =
    remaining === null
      ? 'yeni'
      : remaining > 0
        ? `${remaining} gün`
        : remaining === 0
          ? 'bugün'
          : `+${-remaining} gün`;
  const ringHint =
    remaining === null
      ? 'ritmi henüz öğrenilmedi'
      : remaining > 0
        ? `her zamanki aralığa ${remaining} gün kaldı`
        : remaining === 0
          ? 'her zamanki aralık bugün doluyor'
          : `her zamanki aralığı ${-remaining} gün aştı`;

  return {
    days,
    typical,
    ratio,
    late,
    tier,
    pct,
    remaining,
    ringLabel,
    ringHint,
    meta,
  };
}

export type DecoratedCard = Card & CardStats;

export function decorate(card: Card, today: DateKey): DecoratedCard {
  return { ...card, ...statsFor(card, today) };
}

/**
 * Overdue cards first, then everything else — each group by `ratio` descending,
 * so the most-neglected thing is always the first card on screen.
 */
export function orderCards(cards: DecoratedCard[]): DecoratedCard[] {
  const late = cards.filter((c) => c.late).sort((a, b) => b.ratio - a.ratio);
  const rest = cards.filter((c) => !c.late).sort((a, b) => b.ratio - a.ratio);
  return late.concat(rest);
}
