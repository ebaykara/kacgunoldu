import React, { useRef } from 'react';
import { Animated, Easing, Pressable, StyleSheet, Text, View } from 'react-native';
import Svg, { Path } from 'react-native-svg';
import { color, motion, space } from '../theme/tokens';
import { display, overline, ui } from '../theme/typography';

const EMPHASIZED = Easing.bezier(...motion.emphasized);

type Props = {
  /** `18 Eylül 2026` */
  dateLabel: string;
  lateCount: number;
  topInset: number;
  /** True while the overdue filter is the active one. */
  showingLate: boolean;
  /** Tapping the pill jumps to the overdue cards, and back again. */
  onToggleLate: () => void;
};

function Chevron({ tint, open }: { tint: string; open: boolean }) {
  return (
    <Svg width={9} height={9} viewBox="0 0 9 9" fill="none">
      <Path
        d={open ? 'M1.6 5.6L4.5 2.7L7.4 5.6' : 'M3 1.6L5.9 4.5L3 7.4'}
        stroke={tint}
        strokeWidth={1.6}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </Svg>
  );
}

/**
 * Pinned header block — MD3 large top app bar / HIG large title.
 * It does not scroll: the date and the overdue count stay readable at all times.
 */
export function Header({ dateLabel, lateCount, topInset, showingLate, onToggleLate }: Props) {
  const press = useRef(new Animated.Value(0)).current;
  const hasLate = lateCount > 0;

  const to = (v: number) =>
    Animated.timing(press, { toValue: v, duration: 140, easing: EMPHASIZED, useNativeDriver: true }).start();

  const pillBody = (
    <>
      <View style={[styles.dot, showingLate && styles.dotOn]} />
      <Text style={[styles.pillText, showingLate && styles.pillTextOn]} maxFontSizeMultiplier={1.3}>
        {hasLate ? `${lateCount} kart gecikti` : 'her şey yerinde'}
      </Text>
      {hasLate ? (
        <Chevron tint={showingLate ? color.onPrimary : color.onOverduePill} open={showingLate} />
      ) : null}
    </>
  );

  return (
    <View style={[styles.root, { paddingTop: topInset }]}>
      <View style={styles.row}>
        <Text style={styles.date} maxFontSizeMultiplier={1.3}>
          {dateLabel}
        </Text>

        {hasLate ? (
          // With overdue cards the pill is the shortcut to them; with none
          // there is nothing to show, so it stays a plain status label.
          <Animated.View
            style={{ transform: [{ scale: press.interpolate({ inputRange: [0, 1], outputRange: [1, 0.95] }) }] }}
          >
            <Pressable
              onPress={onToggleLate}
              onPressIn={() => to(1)}
              onPressOut={() => to(0)}
              accessibilityRole="button"
              accessibilityState={{ selected: showingLate }}
              aria-selected={showingLate}
              accessibilityLabel={`${lateCount} kart gecikti`}
              accessibilityHint={showingLate ? 'bütün kartlara dönmek için dokun' : 'gecikenleri görmek için dokun'}
              hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}
              style={[styles.pill, showingLate && styles.pillOn]}
            >
              {pillBody}
            </Pressable>
          </Animated.View>
        ) : (
          <View style={styles.pill} accessibilityRole="text" accessibilityLabel="her şey yerinde">
            {pillBody}
          </View>
        )}
      </View>

      <Text style={styles.title} maxFontSizeMultiplier={1.3} accessibilityRole="header">
        En son ne zaman?
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  root: {
    paddingHorizontal: space.s20,
    paddingBottom: space.s6,
    backgroundColor: color.surface,
    zIndex: 2,
  },
  row: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: space.s12 },
  date: { ...overline, color: color.outline, flexShrink: 1 },
  pill: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: space.s6,
    paddingVertical: 5,
    paddingLeft: space.s8,
    paddingRight: 11,
    borderRadius: 999,
    backgroundColor: color.primaryContainer,
  },
  pillOn: { backgroundColor: color.primary },
  dot: { width: 6, height: 6, borderRadius: 9, backgroundColor: color.primary },
  dotOn: { backgroundColor: color.onPrimary },
  pillText: { ...ui(11, 700), color: color.onOverduePill },
  pillTextOn: { color: color.onPrimary },
  title: {
    ...display(37, 37 * 1.04, 37 * -0.012),
    color: color.onSurface,
    marginTop: space.s12,
  },
});
