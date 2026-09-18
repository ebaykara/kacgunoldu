import React, { useMemo, useRef, useState } from 'react';
import { Animated, Easing, Pressable, StyleProp, StyleSheet, Text, View, ViewStyle } from 'react-native';
import { DOW, DateKey, formatDayMonth, fromDateKey, shiftDays } from '../domain/date';
import type { DecoratedCard } from '../domain/logic';
import { color, layout, motion, radius, space } from '../theme/tokens';
import { display, overline, ui } from '../theme/typography';
import { TrashIcon } from './icons';

const EASE = Easing.out(Easing.ease);

/** A tile that dips on press, used by both the quick picks and the day grid. */
function PressTile({
  onPress,
  style,
  pressedScale,
  accessibilityLabel,
  children,
}: {
  onPress: () => void;
  style: StyleProp<ViewStyle>;
  pressedScale: number;
  accessibilityLabel: string;
  children: React.ReactNode;
}) {
  const v = useRef(new Animated.Value(0)).current;
  const to = (x: number) =>
    Animated.timing(v, { toValue: x, duration: 140, easing: EASE, useNativeDriver: true }).start();

  return (
    <Animated.View
      style={[style, { transform: [{ scale: v.interpolate({ inputRange: [0, 1], outputRange: [1, pressedScale] }) }] }]}
    >
      <Pressable
        onPress={onPress}
        onPressIn={() => to(1)}
        onPressOut={() => to(0)}
        accessibilityRole="button"
        accessibilityLabel={accessibilityLabel}
        style={styles.fill}
      >
        {children}
      </Pressable>
    </Animated.View>
  );
}

type Props = {
  card: DecoratedCard;
  today: DateKey;
  onPick: (offset: number) => void;
  /** Delete the card — the only other thing you can do with it from here. */
  onDelete: () => void;
};

/**
 * "Ne zaman yaptın?" — the record sheet.
 *
 * Three quick picks plus the last fourteen days. Picking anything records
 * immediately and closes; there is no confirm step and no destructive action.
 */
export function RecordSheet({ card, today, onPick, onDelete }: Props) {
  // A 7-column grid: measure once, then size cells exactly so the 6pt gutters
  // land where the design puts them regardless of screen width.
  const [gridWidth, setGridWidth] = useState(0);
  const cellWidth = gridWidth ? (gridWidth - space.s6 * 6) / 7 : 0;

  const quick = useMemo(
    () =>
      ([0, 1, 2] as const).map((o) => ({
        offset: o,
        label: o === 0 ? 'Bugün' : o === 1 ? 'Dün' : '2 gün önce',
        sub: formatDayMonth(shiftDays(today, -o), today),
      })),
    [today],
  );

  // Offsets 3…16 — the two weeks behind the quick picks.
  const cells = useMemo(
    () =>
      Array.from({ length: 14 }, (_, i) => {
        const offset = i + 3;
        const d = fromDateKey(shiftDays(today, -offset));
        return { offset, dow: DOW[d.getDay()], dom: d.getDate() };
      }),
    [today],
  );

  return (
    <View>
      <View style={styles.headRow}>
        <Text style={styles.overline} maxFontSizeMultiplier={1.3}>
          Ne zaman yaptın?
        </Text>
        <Pressable
          onPress={onDelete}
          accessibilityRole="button"
          accessibilityLabel="Kartı sil"
          hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
          style={styles.deleteButton}
        >
          <TrashIcon color={color.outline} />
        </Pressable>
      </View>
      <Text style={styles.title} maxFontSizeMultiplier={1.3} accessibilityRole="header">
        {card.name}
      </Text>
      <Text style={styles.note} maxFontSizeMultiplier={1.4}>
        {card.meta}
      </Text>

      <View style={styles.quickRow}>
        {quick.map((q) => (
          <PressTile
            key={q.offset}
            onPress={() => onPick(q.offset)}
            style={styles.quickTile}
            pressedScale={0.96}
            accessibilityLabel={`${q.label}, ${q.sub}`}
          >
            <Text style={styles.quickLabel} maxFontSizeMultiplier={1.3}>
              {q.label}
            </Text>
            <Text style={styles.quickSub} maxFontSizeMultiplier={1.3}>
              {q.sub}
            </Text>
          </PressTile>
        ))}
      </View>

      <Text style={[styles.overline, styles.gridOverline]} maxFontSizeMultiplier={1.3}>
        Daha geriden seç
      </Text>

      <View
        style={styles.grid}
        onLayout={(e) => setGridWidth(e.nativeEvent.layout.width)}
      >
        {cells.map((c) => (
          <PressTile
            key={c.offset}
            onPress={() => onPick(c.offset)}
            style={[styles.dayCell, cellWidth ? { width: cellWidth } : null]}
            pressedScale={0.94}
            accessibilityLabel={`${c.offset} gün önce, ${c.dow} ${c.dom}`}
          >
            <Text style={styles.dayDow} maxFontSizeMultiplier={1.2}>
              {c.dow}
            </Text>
            <Text style={styles.dayDom} maxFontSizeMultiplier={1.2}>
              {c.dom}
            </Text>
          </PressTile>
        ))}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  fill: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  headRow: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
  deleteButton: { padding: space.xs },
  overline: { ...overline, color: color.outline },
  gridOverline: { marginTop: space.s18, marginBottom: 10 },
  title: { ...display(26, 26 * 1.14), color: color.onSurface, marginTop: space.s6, marginBottom: 3 },
  note: { ...ui(12.5, 400), color: color.onSurfaceVariant, marginBottom: space.s15 },

  quickRow: { flexDirection: 'row', gap: space.s8 },
  quickTile: {
    flex: 1,
    minHeight: layout.minTouchTarget + 14,
    paddingVertical: space.s14,
    paddingHorizontal: space.s6,
    borderRadius: radius.tile,
    backgroundColor: color.primaryContainer,
    overflow: 'hidden',
  },
  quickLabel: { ...ui(14, 700), color: color.onPrimaryContainer, textAlign: 'center' },
  quickSub: { ...ui(10.5, 500), color: color.onOverduePill, marginTop: 3, textAlign: 'center' },

  grid: { flexDirection: 'row', flexWrap: 'wrap', gap: space.s6 },
  dayCell: {
    // Height is padded to the 44pt minimum touch target even though the mock
    // draws the cell visually shorter.
    minHeight: layout.minTouchTarget,
    paddingVertical: space.s7,
    borderRadius: radius.dayCell,
    backgroundColor: color.surfaceContainer,
    overflow: 'hidden',
  },
  dayDow: { ...ui(9.5, 700), color: color.outline, textTransform: 'uppercase' },
  dayDom: { ...ui(14, 600), color: color.onSurface, marginTop: 2 },
});
