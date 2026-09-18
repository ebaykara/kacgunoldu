import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { AppState, AppStateStatus } from 'react-native';
import { DateKey, msUntilMidnight, relativeLabel, shiftDays, todayKey } from '../domain/date';
import { applyOrder } from '../domain/order';
import { capitalizeTr } from '../domain/text';
import type { Card } from '../domain/types';
import { loadCards, loadManualOrder, saveCards, saveManualOrder } from '../storage/repository';
import { snackbarTimeout } from '../theme/tokens';

export type Snack = {
  message: string;
  /** Only records can be undone — creating a card offers no undo. */
  undoable: boolean;
};

/** Newest-first insert that treats a day as recorded at most once. */
function insertRecord(recs: DateKey[], key: DateKey): DateKey[] {
  const next = recs.filter((r) => r !== key);
  const at = next.findIndex((r) => r < key);
  if (at === -1) next.push(key);
  else next.splice(at, 0, key);
  return next;
}

export function useCardStore() {
  const [cards, setCards] = useState<Card[]>([]);
  /**
   * `null` = no one has dragged a card yet, so the grid sorts itself by
   * urgency. Once set, this exact id order wins over the automatic sort.
   */
  const [manualOrder, setManualOrderState] = useState<string[] | null>(null);
  const [ready, setReady] = useState(false);
  const [today, setToday] = useState<DateKey>(() => todayKey());
  const [snack, setSnack] = useState<Snack | null>(null);
  /** Bumped on every record so the screen can replay the celebration. */
  const [recordPulse, setRecordPulse] = useState<{ id: string; nonce: number } | null>(null);

  const undoRef = useRef<{ id: string; recs: DateKey[] } | null>(null);
  const snackTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const midnightTimer = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    let alive = true;
    Promise.all([loadCards(), loadManualOrder()]).then(([loadedCards, loadedOrder]) => {
      if (!alive) return;
      setCards(loadedCards);
      setManualOrderState(loadedOrder);
      setReady(true);
    });
    return () => {
      alive = false;
    };
  }, []);

  /**
   * Day counts are calendar-based, so "today" has to be re-read at local
   * midnight and again whenever the app comes back to the foreground.
   */
  const refreshToday = useCallback(() => {
    setToday((prev) => {
      const next = todayKey();
      return next === prev ? prev : next;
    });
  }, []);

  useEffect(() => {
    const scheduleMidnight = () => {
      if (midnightTimer.current) clearTimeout(midnightTimer.current);
      midnightTimer.current = setTimeout(() => {
        refreshToday();
        scheduleMidnight();
      }, msUntilMidnight());
    };
    scheduleMidnight();

    const onAppState = (status: AppStateStatus) => {
      if (status === 'active') {
        refreshToday();
        scheduleMidnight();
      }
    };
    const sub = AppState.addEventListener('change', onAppState);
    return () => {
      sub.remove();
      if (midnightTimer.current) clearTimeout(midnightTimer.current);
    };
  }, [refreshToday]);

  const commit = useCallback((next: Card[]) => {
    setCards(next);
    void saveCards(next);
  }, []);

  /**
   * The grid's actual display order: the saved drag arrangement if there is
   * one, otherwise urgency (overdue first, then soonest-due). A card that
   * isn't in a saved arrangement yet — just created, or from before dragging
   * existed — sorts to the front, matching where a new card has always
   * appeared.
   */
  const orderedCards = useMemo<Card[]>(
    () => applyOrder(cards, manualOrder, today),
    [cards, manualOrder, today],
  );

  /** Persist a drag-and-drop rearrangement as the new permanent order. */
  const reorder = useCallback((newOrderIds: string[]) => {
    setManualOrderState(newOrderIds);
    void saveManualOrder(newOrderIds);
  }, []);

  const showSnack = useCallback((next: Snack) => {
    if (snackTimer.current) clearTimeout(snackTimer.current);
    setSnack(next);
    snackTimer.current = setTimeout(() => {
      setSnack(null);
      undoRef.current = null;
    }, next.undoable ? snackbarTimeout.record : snackbarTimeout.create);
  }, []);

  const dismissSnack = useCallback(() => {
    if (snackTimer.current) clearTimeout(snackTimer.current);
    setSnack(null);
    undoRef.current = null;
  }, []);

  /** Record `card` as done `offset` days ago. */
  const record = useCallback(
    (cardId: string, offset: number) => {
      const card = cards.find((c) => c.id === cardId);
      if (!card) return;
      const key = shiftDays(today, -offset);
      undoRef.current = { id: card.id, recs: card.recs };
      commit(cards.map((c) => (c.id === card.id ? { ...c, recs: insertRecord(c.recs, key) } : c)));
      setRecordPulse({ id: card.id, nonce: Date.now() });
      showSnack({ message: `${card.name} · ${relativeLabel(offset)}`, undoable: true });
    },
    [cards, today, commit, showSnack],
  );

  /** Restore the card's previous record list exactly. */
  const undo = useCallback(() => {
    const u = undoRef.current;
    if (!u) return;
    commit(cards.map((c) => (c.id === u.id ? { ...c, recs: u.recs } : c)));
    undoRef.current = null;
    setRecordPulse(null);
    if (snackTimer.current) clearTimeout(snackTimer.current);
    setSnack(null);
  }, [cards, commit]);

  /**
   * Create a card and return its id.
   *
   * `offset === null` leaves the card without a first record — the create
   * sheet then opens the record sheet so the date can be picked.
   */
  const addCard = useCallback(
    (rawName: string, offset: number | null): string | null => {
      const trimmed = rawName.trim();
      if (!trimmed) return null;
      // The field invites a lowercase, first-person sentence ("çamaşır
      // yıkadım"); the grid reads better as a list, so the stored name gets
      // a capital first letter while the field itself stays untouched.
      const name = capitalizeTr(trimmed);
      const card: Card = {
        id: `${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 8)}`,
        name,
        recs: offset === null ? [] : [shiftDays(today, -offset)],
      };
      undoRef.current = null;
      commit([card, ...cards]);
      if (offset !== null) showSnack({ message: `“${name}” eklendi`, undoable: false });
      return card.id;
    },
    [cards, today, commit, showSnack],
  );

  /**
   * Delete a card and everything recorded on it.
   *
   * Destructive and not undoable, so the caller confirms first — see the
   * long-press flow on the card.
   */
  const deleteCard = useCallback(
    (cardId: string) => {
      const card = cards.find((c) => c.id === cardId);
      if (!card) return;
      undoRef.current = null;
      setRecordPulse(null);
      commit(cards.filter((c) => c.id !== cardId));
      if (manualOrder) {
        const next = manualOrder.filter((id) => id !== cardId);
        setManualOrderState(next);
        void saveManualOrder(next);
      }
      showSnack({ message: `“${card.name}” silindi`, undoable: false });
    },
    [cards, manualOrder, commit, showSnack],
  );

  const clearPulse = useCallback(() => setRecordPulse(null), []);

  useEffect(
    () => () => {
      if (snackTimer.current) clearTimeout(snackTimer.current);
    },
    [],
  );

  return {
    cards: orderedCards,
    ready,
    today,
    snack,
    recordPulse,
    record,
    undo,
    addCard,
    deleteCard,
    reorder,
    dismissSnack,
    clearPulse,
  };
}
