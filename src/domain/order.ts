import { decorate, orderCards } from './logic';
import type { Card } from './types';
import type { DateKey } from './date';

/**
 * The grid's actual display order.
 *
 * With no saved arrangement, cards sort by urgency (overdue first, then
 * soonest-due) — see `orderCards`. Once someone drags a card, `manualOrder`
 * holds the exact id sequence they left it in, and that wins from then on.
 *
 * A card missing from `manualOrder` — just created, or from before dragging
 * existed — sorts to the front, matching where a new card has always
 * appeared in this app.
 */
export function applyOrder(cards: Card[], manualOrder: string[] | null, today: DateKey): Card[] {
  if (manualOrder && manualOrder.length) {
    const position = new Map(manualOrder.map((id, i) => [id, i]));
    return cards.slice().sort((a, b) => {
      const pa = position.has(a.id) ? position.get(a.id)! : -1;
      const pb = position.has(b.id) ? position.get(b.id)! : -1;
      return pa - pb;
    });
  }
  const decorated = cards.map((c) => decorate(c, today));
  const byId = new Map(cards.map((c) => [c.id, c]));
  return orderCards(decorated).map((c) => byId.get(c.id)!);
}
