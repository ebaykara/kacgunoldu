import AsyncStorage from '@react-native-async-storage/async-storage';
import type { Card } from '../domain/types';
import { seedCards } from './seed';

const KEY = 'nezaman.cards.v1';
const ORDER_KEY = 'nezaman.order.v1';
const DATE_KEY = /^\d{4}-\d{2}-\d{2}$/;

function isCard(value: unknown): value is Card {
  if (typeof value !== 'object' || value === null) return false;
  const c = value as Record<string, unknown>;
  return (
    typeof c.id === 'string' &&
    typeof c.name === 'string' &&
    Array.isArray(c.recs) &&
    c.recs.every((r) => typeof r === 'string' && DATE_KEY.test(r))
  );
}

/**
 * Local-first, no backend. Anything unreadable falls back to the seed rather
 * than to a crash — losing demo content beats losing the app.
 */
export async function loadCards(): Promise<Card[]> {
  try {
    const raw = await AsyncStorage.getItem(KEY);
    if (raw === null) {
      const seeded = seedCards();
      await saveCards(seeded);
      return seeded;
    }
    const parsed: unknown = JSON.parse(raw);
    if (!Array.isArray(parsed)) return seedCards();
    const cards = parsed.filter(isCard);
    // Records are kept newest-first; re-sort defensively on read.
    return cards.map((c) => ({ ...c, recs: [...c.recs].sort((a, b) => (a < b ? 1 : a > b ? -1 : 0)) }));
  } catch {
    return seedCards();
  }
}

export async function saveCards(cards: Card[]): Promise<void> {
  try {
    await AsyncStorage.setItem(KEY, JSON.stringify(cards));
  } catch {
    // Persistence is best-effort; the in-memory state stays authoritative.
  }
}

/**
 * The grid sorts itself by urgency until someone drags a card — at that
 * point their arrangement is remembered here as an explicit id order, and
 * takes over from the automatic sort for good.
 */
export async function loadManualOrder(): Promise<string[] | null> {
  try {
    const raw = await AsyncStorage.getItem(ORDER_KEY);
    if (raw === null) return null;
    const parsed: unknown = JSON.parse(raw);
    if (!Array.isArray(parsed) || !parsed.every((id) => typeof id === 'string')) return null;
    return parsed;
  } catch {
    return null;
  }
}

export async function saveManualOrder(order: string[]): Promise<void> {
  try {
    await AsyncStorage.setItem(ORDER_KEY, JSON.stringify(order));
  } catch {
    // Best-effort, same as saveCards.
  }
}
