import { shiftDays } from '../date';
import { applyOrder } from '../order';
import type { Card } from '../types';

const TODAY = '2026-09-18';

const card = (id: string, offsets: number[]): Card => ({
  id,
  name: id,
  recs: offsets.map((o) => shiftDays(TODAY, -o)),
});

describe('applyOrder — with no saved arrangement', () => {
  it('falls back to urgency: overdue first, then soonest-due', () => {
    const cards = [
      card('fresh', [2, 12, 22, 32]), // ratio 0.2
      card('late', [11, 14, 18, 20, 23]), // typical 3, days 11 -> late
      card('calm', [20, 30, 40, 50]), // ratio 0.67
    ];
    const result = applyOrder(cards, null, TODAY);
    expect(result.map((c) => c.id)).toEqual(['late', 'calm', 'fresh']);
  });
});

describe('applyOrder — with a saved arrangement', () => {
  it('respects the exact saved sequence, ignoring urgency', () => {
    const cards = [
      card('a', [11, 14, 18, 20, 23]), // would be "late" and sort first automatically
      card('b', [2, 12, 22, 32]),
      card('c', [20, 30, 40, 50]),
    ];
    // The person dragged the most-urgent card to the bottom on purpose.
    const result = applyOrder(cards, ['b', 'c', 'a'], TODAY);
    expect(result.map((c) => c.id)).toEqual(['b', 'c', 'a']);
  });

  it('puts a card missing from the saved order at the front', () => {
    // "new" was created after the last drag, so it has no saved position —
    // matches where a freshly created card has always appeared.
    const cards = [card('a', [5]), card('b', [9]), card('new', [0])];
    const result = applyOrder(cards, ['a', 'b'], TODAY);
    expect(result.map((c) => c.id)).toEqual(['new', 'a', 'b']);
  });

  it('is stable when two cards are both missing from the saved order', () => {
    // Two cards added without ever dragging: both sort to the front, but
    // keep their relative order (Array#sort is a stable sort in JS).
    const cards = [card('older', [5]), card('newer', [1]), card('a', [9])];
    const result = applyOrder(cards, ['a'], TODAY);
    expect(result.map((c) => c.id)).toEqual(['older', 'newer', 'a']);
  });

  it('ignores ids in the saved order that no longer exist', () => {
    // "gone" was deleted; its ghost entry in a stale saved order must not
    // blow up the sort or shift anyone else's position.
    const cards = [card('a', [5]), card('b', [9])];
    const result = applyOrder(cards, ['gone', 'b', 'a'], TODAY);
    expect(result.map((c) => c.id)).toEqual(['b', 'a']);
  });

  it('treats an empty saved order the same as none — falls back to urgency', () => {
    const cards = [card('late', [11, 14, 18, 20, 23]), card('fresh', [2, 12, 22, 32])];
    const result = applyOrder(cards, [], TODAY);
    expect(result.map((c) => c.id)).toEqual(['late', 'fresh']);
  });
});
