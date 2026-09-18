import React, { useEffect, useRef } from 'react';
import { Animated, Easing, StyleSheet, Text, View } from 'react-native';
import Svg, { Circle } from 'react-native-svg';
import { layout, motion } from '../theme/tokens';
import { ui } from '../theme/typography';

const AnimatedCircle = Animated.createAnimatedComponent(Circle);

const SIZE = layout.ringSize;
const STROKE = (layout.ringSize - layout.ringHoleSize) / 2;
const R = (SIZE - STROKE) / 2;
const CIRCUMFERENCE = 2 * Math.PI * R;

type Props = {
  /** Fill percentage, 3–100. */
  pct: number;
  ring: string;
  track: string;
  ink: string;
  label: string;
  reduceMotion: boolean;
};

/**
 * The rhythm ring: how far through its typical interval this card is.
 *
 * The mock draws a conic gradient; the native equivalent is a trimmed arc,
 * starting at 12 o'clock and sweeping clockwise.
 */
export function RhythmRing({ pct, ring, track, ink, label, reduceMotion }: Props) {
  const progress = useRef(new Animated.Value(pct)).current;

  useEffect(() => {
    if (reduceMotion) {
      progress.setValue(pct);
      return;
    }
    const anim = Animated.timing(progress, {
      toValue: pct,
      duration: motion.ring,
      easing: Easing.inOut(Easing.ease),
      useNativeDriver: false,
    });
    anim.start();
    return () => anim.stop();
  }, [pct, progress, reduceMotion]);

  const dashOffset = progress.interpolate({
    inputRange: [0, 100],
    outputRange: [CIRCUMFERENCE, 0],
  });

  return (
    <View style={styles.root} accessibilityElementsHidden importantForAccessibility="no-hide-descendants">
      {/* The whole canvas is rotated so the sweep starts at 12 o'clock;
          the label sits outside it and stays upright. */}
      <View style={styles.canvas}>
        <Svg width={SIZE} height={SIZE}>
          <Circle cx={SIZE / 2} cy={SIZE / 2} r={R} stroke={track} strokeWidth={STROKE} fill="none" />
          <AnimatedCircle
            cx={SIZE / 2}
            cy={SIZE / 2}
            r={R}
            stroke={ring}
            strokeWidth={STROKE}
            fill="none"
            strokeDasharray={CIRCUMFERENCE}
            strokeDashoffset={dashOffset}
            strokeLinecap="butt"
          />
        </Svg>
      </View>
      <View style={styles.labelWrap}>
        <Text
          style={[styles.label, { color: ink }]}
          numberOfLines={1}
          adjustsFontSizeToFit
          minimumFontScale={0.7}
          allowFontScaling={false}
        >
          {label}
        </Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { width: SIZE, height: SIZE },
  canvas: { transform: [{ rotate: '-90deg' }] },
  labelWrap: {
    ...StyleSheet.absoluteFill,
    alignItems: 'center',
    justifyContent: 'center',
    // Keep the text inside the hole, not on top of the arc.
    paddingHorizontal: (SIZE - layout.ringHoleSize) / 2 + 2,
    pointerEvents: 'none',
  },
  label: { ...ui(9, 700), letterSpacing: 0, opacity: 0.85, textAlign: 'center' },
});
