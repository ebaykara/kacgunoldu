import React, { useCallback, useMemo, useState } from 'react';
import { ScrollView, StyleSheet, View, useWindowDimensions } from 'react-native';
import * as Haptics from 'expo-haptics';
import { NestableDraggableFlatList, NestableScrollContainer, ScaleDecorator } from 'react-native-draggable-flatlist';
import { useReducedMotion } from 'react-native-reanimated';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { CardTile } from '../components/CardTile';
import { confirmDestructive } from '../components/confirmDestructive';
import { CreateSheet } from '../components/CreateSheet';
import { EmptyState } from '../components/EmptyState';
import { Fab } from '../components/Fab';
import { Header } from '../components/Header';
import { RecordSheet } from '../components/RecordSheet';
import { Sheet } from '../components/Sheet';
import { Snackbar } from '../components/Snackbar';
import { TabBar } from '../components/TabBar';
import { Timeline, TimelineGroup } from '../components/Timeline';

import { MONTHS_SHORT, daysSince, formatFullDate, fromDateKey, relativeLabel, shiftDays } from '../domain/date';
import { decorate, type DecoratedCard } from '../domain/logic';
import type { Tab } from '../domain/types';
import { useCardStore } from '../state/useCardStore';
import { color, layout, space } from '../theme/tokens';

/** Records shown per card in the timeline, and how far back it reaches. */
const TIMELINE_RECORDS_PER_CARD = 4;
const TIMELINE_MAX_AGE_DAYS = 120;
const TIMELINE_MAX_GROUPS = 14;

export function HomeScreen() {
  const insets = useSafeAreaInsets();
  const { width: windowWidth } = useWindowDimensions();
  const reduceMotion = useReducedMotion();
  const { cards, ready, today, snack, recordPulse, record, undo, addCard, deleteCard, reorder } = useCardStore();

  const [tab, setTab] = useState<Tab>('cards');
  /**
   * The one remaining filter. It used to be a three-way chip row (Tümü /
   * Gecikenler / Taze); that row is gone, and the overdue pill in the header
   * is now the only way in or out of this view.
   */
  const [onlyLate, setOnlyLate] = useState(false);
  const [sheetId, setSheetId] = useState<string | null>(null);
  const [adding, setAdding] = useState(false);
  const [draft, setDraft] = useState('');

  // `cards` already arrives in display order -- either the saved drag
  // arrangement or, failing that, urgency (overdue first, then soonest-due).
  // Decorating preserves that order.
  const decorated = useMemo(() => cards.map((c) => decorate(c, today)), [cards, today]);
  const lateCount = useMemo(() => decorated.filter((c) => c.late).length, [decorated]);
  const visible = onlyLate ? decorated.filter((c) => c.late) : decorated;

  const timeline = useMemo<TimelineGroup[]>(() => {
    const byDay = new Map<number, string[]>();
    for (const c of cards) {
      for (const key of c.recs.slice(0, TIMELINE_RECORDS_PER_CARD)) {
        const offset = daysSince(key, today);
        if (offset > TIMELINE_MAX_AGE_DAYS || offset < 0) continue;
        const bucket = byDay.get(offset);
        if (bucket) bucket.push(c.name);
        else byDay.set(offset, [c.name]);
      }
    }
    return [...byDay.keys()]
      .sort((a, b) => a - b)
      .slice(0, TIMELINE_MAX_GROUPS)
      .map((offset) => {
        const d = fromDateKey(shiftDays(today, -offset));
        return {
          key: String(offset),
          dom: d.getDate(),
          mon: MONTHS_SHORT[d.getMonth()],
          rel: relativeLabel(offset),
          items: byDay.get(offset) ?? [],
        };
      });
  }, [cards, today]);

  const sheetCard = useMemo(
    () => (sheetId ? (decorated.find((c) => c.id === sheetId) ?? null) : null),
    [decorated, sheetId],
  );

  const onPickDate = useCallback(
    (offset: number) => {
      if (!sheetId) return;
      const id = sheetId;
      setSheetId(null);
      record(id, offset);
      if (!reduceMotion) {
        Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light).catch(() => {});
      }
    },
    [sheetId, record, reduceMotion],
  );

  /**
   * Deleting takes every record on the card with it and cannot be undone, so
   * it always goes through a confirmation first. Reachable from the record
   * sheet, not from the card itself -- long-press on the card now starts a
   * drag instead.
   */
  const confirmDelete = useCallback(
    (cardId: string, name: string) => {
      if (!reduceMotion) {
        Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium).catch(() => {});
      }
      confirmDestructive({
        title: `"${name}" silinsin mi?`,
        message: 'Bu kartın bütün kayıtları kalıcı olarak silinir. Bu işlem geri alınamaz.',
        confirmLabel: 'Sil',
        cancelLabel: 'Vazgeç',
        onConfirm: () => {
          setSheetId(null);
          deleteCard(cardId);
        },
      });
    },
    [deleteCard, reduceMotion],
  );

  const tabBarHeight = layout.tabBarContentHeight + insets.bottom;
  // Two fixed columns. Derived from the window rather than measured with
  // onLayout, so the grid never renders a zero-width first pass.
  const columnWidth = (windowWidth - space.s18 * 2 - layout.cardGap) / 2;

  const scrollPadding = {
    paddingTop: 2,
    paddingHorizontal: space.s18,
    paddingBottom: layout.gridBottomPadding + insets.bottom,
  };

  const renderTile = useCallback(
    (card: DecoratedCard, opts?: { drag?: () => void; isActive?: boolean }) => (
      <View style={{ width: columnWidth, marginBottom: layout.cardGap }}>
        <CardTile
          card={card}
          onPress={() => setSheetId(card.id)}
          onLongPress={opts?.drag}
          isActive={opts?.isActive}
          celebrateNonce={recordPulse && recordPulse.id === card.id ? recordPulse.nonce : null}
          showRing
          reduceMotion={reduceMotion}
        />
      </View>
    ),
    [columnWidth, recordPulse, reduceMotion],
  );

  return (
    <View style={styles.root}>
      <Header
        dateLabel={formatFullDate(today)}
        lateCount={lateCount}
        topInset={insets.top + space.s12}
        showingLate={onlyLate}
        onToggleLate={() => {
          setTab('cards');
          setOnlyLate((v) => !v);
        }}
      />

      <View style={styles.body}>
        {/* Both tabs stay mounted so each keeps its own scroll position. */}
        <View style={[styles.full, tab !== 'cards' && styles.hidden]}>
          {onlyLate ? (
            // A temporary, filtered view -- dragging here would have nowhere
            // stable to persist, so it stays a plain, auto-sorted list.
            <ScrollView contentContainerStyle={scrollPadding} showsVerticalScrollIndicator={false}>
              <View style={styles.grid}>
                {visible.map((card) => (
                  <View key={card.id} style={{ width: columnWidth }}>
                    {renderTile(card)}
                  </View>
                ))}
              </View>
              {ready && visible.length === 0 ? <EmptyState onlyLate reduceMotion={reduceMotion} /> : null}
            </ScrollView>
          ) : (
            <NestableScrollContainer contentContainerStyle={scrollPadding} showsVerticalScrollIndicator={false}>
              <NestableDraggableFlatList
                data={visible}
                keyExtractor={(card) => card.id}
                numColumns={2}
                scrollEnabled={false}
                columnWrapperStyle={styles.columnWrapper}
                activationDistance={12}
                renderItem={({ item, drag, isActive }) => (
                  <ScaleDecorator activeScale={1.04}>{renderTile(item, { drag, isActive })}</ScaleDecorator>
                )}
                onDragEnd={({ data }) => reorder(data.map((c) => c.id))}
              />
              {ready && visible.length === 0 ? <EmptyState onlyLate={false} reduceMotion={reduceMotion} /> : null}
            </NestableScrollContainer>
          )}
        </View>

        <View style={[styles.full, tab !== 'time' && styles.hidden]}>
          <ScrollView contentContainerStyle={scrollPadding} showsVerticalScrollIndicator={false}>
            <Timeline groups={timeline} />
          </ScrollView>
        </View>
      </View>

      <Fab onPress={() => { setDraft(''); setAdding(true); }} bottom={tabBarHeight + space.s20} />

      <TabBar value={tab} onChange={setTab} bottomInset={insets.bottom} />

      {snack ? (
        <Snackbar
          message={snack.message}
          undoable={snack.undoable}
          onUndo={undo}
          bottom={tabBarHeight + space.s12}
          reduceMotion={reduceMotion}
        />
      ) : null}

      <Sheet
        visible={sheetCard !== null}
        onClose={() => setSheetId(null)}
        bottomInset={insets.bottom}
        reduceMotion={reduceMotion}
      >
        {sheetCard ? (
          <RecordSheet
            card={sheetCard}
            today={today}
            onPick={onPickDate}
            onDelete={() => confirmDelete(sheetCard.id, sheetCard.name)}
          />
        ) : null}
      </Sheet>

      <Sheet
        visible={adding}
        onClose={() => setAdding(false)}
        avoidKeyboard
        bottomInset={insets.bottom}
        reduceMotion={reduceMotion}
      >
        <CreateSheet
          value={draft}
          onChange={setDraft}
          onAddAndPickDate={() => {
            const name = draft;
            setAdding(false);
            setDraft('');
            const id = addCard(name, null);
            // Hand straight over to the record sheet for the new card.
            if (id) setSheetId(id);
          }}
          onAddToday={() => {
            const name = draft;
            setAdding(false);
            setDraft('');
            addCard(name, 0);
          }}
        />
      </Sheet>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: color.surface },
  body: { flex: 1, minHeight: 0 },
  full: { flex: 1 },
  hidden: { display: 'none' },
  grid: { flexDirection: 'row', flexWrap: 'wrap', gap: layout.cardGap },
  columnWrapper: { gap: layout.cardGap },
});
