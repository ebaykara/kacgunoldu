import React, { useEffect, useRef } from 'react';
import { Animated, Easing, Pressable, StyleSheet, Text, View } from 'react-native';
import type { DecoratedCard } from '../domain/logic';
import { TIERS } from '../domain/logic';
import { elevation, layout, motion, radius, space } from '../theme/tokens';
import { ui } from '../theme/typography';
import { DayCount } from './DayCount';
import { Halo } from './Halo';
import { RhythmRing } from './RhythmRing';

const EMPHASIZED = Easing.bezier(...motion.emphasized);

type Props = {
  card: DecoratedCard;
  onPress: () => void;
  /**
   * Long press starts a drag (reordering the grid). Omitted where dragging
   * doesn't apply — the filtered "Gecikenler" view keeps the automatic sort.
   */
  onLongPress?: () => void;
  /** True while this card is the one being dragged — it lifts off the grid. */
  isActive?: boolean;
  /** Non-null while this card is celebrating a fresh record. */
  celebrateNonce: number | null;
  showRing: boolean;
  reduceMotion: boolean;
};

/**
 * The core component: one tracked thing.
 *
 * The whole tile is a single button (MD3 filled/tonal card with a state layer;
 * HIG grouped card at 26pt radius). Colour is derived from the tier, but the
 * `geç` tag and the meta line carry the same information so overdue is never
 * signalled by colour alone.
 */
export const CardTile = React.memo(function CardTile({
  card,
  onPress,
  onLongPress,
  isActive = false,
  celebrateNonce,
  showRing,
  reduceMotion,
}: Props) {
  const T = TIERS[card.tier];
  const press = useRef(new Animated.Value(0)).current;
  const pop = useRef(new Animated.Value(1)).current;

  const setPressed = (down: boolean) => {
    Animated.timing(press, {
      toValue: down ? 1 : 0,
      duration: 180,
      easing: EMPHASIZED,
      useNativeDriver: true,
    }).start();
  };

  // scale(1) -> 1.045 -> 0.985 -> 1 over 600ms, matching the CSS keyframes.
  useEffect(() => {
    if (celebrateNonce === null || reduceMotion) return;
    pop.setValue(1);
    const seq = Animated.sequence([
      Animated.timing(pop, { toValue: 1.045, duration: 180, easing: EMPHASIZED, useNativeDriver: true }),
      Animated.timing(pop, { toValue: 0.985, duration: 192, easing: EMPHASIZED, useNativeDriver: true }),
      Animated.timing(pop, { toValue: 1, duration: 228, easing: EMPHASIZED, useNativeDriver: true }),
    ]);
    seq.start();
    return () => {
      seq.stop();
      pop.setValue(1);
    };
  }, [celebrateNonce, pop, reduceMotion]);

  const pressScale = press.interpolate({ inputRange: [0, 1], outputRange: [1, 0.975] });

  return (
    <Animated.View
      style={[
        styles.shadow,
        card.tier === 'late' ? elevation.cardLate : elevation.card,
        isActive && elevation.fab, // a deeper shadow while lifted for dragging
        {
          transform: [
            { scale: pressScale },
            { scale: pop },
            { scale: isActive ? 1.04 : 1 },
          ],
          opacity: isActive ? 0.97 : 1,
        },
      ]}
    >
      <Pressable
        onPress={onPress}
        onLongPress={onLongPress}
        delayLongPress={350}
        onPressIn={() => setPressed(true)}
        onPressOut={() => setPressed(false)}
        accessibilityRole="button"
        accessibilityLabel={`${card.name}, ${card.days} gün önce${card.late ? ', geç' : ''}. ${card.ringHint}`}
        accessibilityHint={onLongPress ? 'işaretlemek için dokun, yer değiştirmek için basılı tutup sürükle' : 'işaretlemek için dokun'}
        style={[styles.card, { backgroundColor: T.bg }]}
      >
        {celebrateNonce !== null && !reduceMotion ? <Halo color={T.ring} nonce={celebrateNonce} /> : null}

        <View style={styles.topRow}>
          <View style={styles.titleBlock}>
            <Text style={[styles.name, { color: T.ink }]} maxFontSizeMultiplier={1.4}>
              {card.name}
            </Text>
            <Text
              style={[styles.meta, { color: T.ink }]}
              maxFontSizeMultiplier={1.4}
              numberOfLines={1}
              // Shrinks a touch before truncating -- the "geç" tag can crowd
              // this line, and a slightly smaller full sentence beats an
              // ellipsis cutting off the interval. (Native only; RN-web has
              // no equivalent and falls back to a plain truncation, same as
              // before.)
              adjustsFontSizeToFit
              minimumFontScale={0.82}
            >
              {card.meta}
            </Text>
          </View>
          {card.late ? (
            <View
              style={[styles.tag, { backgroundColor: T.tag }]}
              accessibilityElementsHidden
              importantForAccessibility="no-hide-descendants"
            >
              <Text
                style={[styles.tagText, { color: card.tier === 'late' ? T.ink : '#FFFFFF' }]}
                maxFontSizeMultiplier={1.2}
                numberOfLines={1}
              >
                {/* Spells out *why* — "8 gün geç" reads on its own, without
                    a separate sentence elsewhere on the card. */}
                {-(card.remaining ?? 0)} gün geç
              </Text>
            </View>
          ) : null}
        </View>

        <View style={styles.bottomRow}>
          <View style={styles.countRow}>
            <DayCount value={card.days} color={T.ink} reduceMotion={reduceMotion} />
            <Text style={[styles.gun, { color: T.ink }]} maxFontSizeMultiplier={1.3}>
              gün
            </Text>
          </View>

          {showRing ? (
            <RhythmRing
              pct={card.pct}
              ring={T.ring}
              track={T.track}
              ink={T.ink}
              label={card.ringLabel}
              reduceMotion={reduceMotion}
            />
          ) : null}
        </View>
      </Pressable>
    </Animated.View>
  );
});

const styles = StyleSheet.create({
  // Shadow lives on the wrapper so the card's own `overflow: hidden`
  // (which clips the halo) cannot clip the elevation.
  shadow: {
    borderRadius: radius.card,
    backgroundColor: 'transparent',
  },
  card: {
    borderRadius: radius.card,
    paddingTop: space.s15,
    paddingHorizontal: space.s15,
    paddingBottom: space.s14,
    minHeight: layout.cardMinHeight,
    overflow: 'hidden',
    justifyContent: 'space-between',
  },
  topRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    justifyContent: 'space-between',
    gap: space.s8,
  },
  titleBlock: { flexShrink: 1 },
  name: {
    ...ui(13.5, 600),
    lineHeight: 13.5 * 1.3,
    letterSpacing: 13.5 * -0.008,
  },
  tag: {
    paddingVertical: space.xs,
    paddingHorizontal: 9,
    borderRadius: radius.pill,
  },
  tagText: {
    // Lowercase and untracked — "8 gün geç" reads as a short label now,
    // not a stretched badge the way the bare "GEÇ" caps did.
    ...ui(9.5, 700),
  },
  bottomRow: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    justifyContent: 'space-between',
    gap: space.s8,
  },
  countRow: { flexDirection: 'row', alignItems: 'baseline', gap: space.xs, flexShrink: 1 },
  gun: { ...ui(12, 600), opacity: 0.66 },
  meta: { ...ui(10.5, 500), marginTop: space.s6, opacity: 0.72, lineHeight: 10.5 * 1.35 },
});
