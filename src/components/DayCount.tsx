import React, { useEffect, useRef, useState } from 'react';
import { Animated, Easing, TextStyle } from 'react-native';
import { motion } from '../theme/tokens';
import { display } from '../theme/typography';

/** The card's headline number. */
export const DAY_COUNT_SIZE = 58;

const numberStyle: TextStyle = {
  ...display(DAY_COUNT_SIZE, DAY_COUNT_SIZE * 0.86, DAY_COUNT_SIZE * -0.02),
};

/**
 * The big day number.
 *
 * On a record it counts down from the old value to the new one over 620ms with
 * a cubic ease-out, rounded each frame. The tween lives inside this component
 * so a running record only re-renders one number, never the grid.
 *
 * Under reduce-motion the value cross-fades instead.
 */
export function DayCount({ value, color, reduceMotion }: { value: number; color: string; reduceMotion: boolean }) {
  const [shown, setShown] = useState(value);
  const shownRef = useRef(value);
  const raf = useRef<number | null>(null);
  const fade = useRef(new Animated.Value(1)).current;

  shownRef.current = shown;

  useEffect(() => {
    if (shownRef.current === value) return;

    if (reduceMotion) {
      const seq = Animated.sequence([
        Animated.timing(fade, { toValue: 0, duration: 110, easing: Easing.out(Easing.ease), useNativeDriver: true }),
        Animated.timing(fade, { toValue: 1, duration: 150, easing: Easing.out(Easing.ease), useNativeDriver: true }),
      ]);
      const timer = setTimeout(() => setShown(value), 110);
      seq.start();
      return () => {
        clearTimeout(timer);
        seq.stop();
      };
    }

    const from = shownRef.current;
    const start = Date.now();
    const step = () => {
      const p = Math.min(1, (Date.now() - start) / motion.countdown);
      const eased = 1 - Math.pow(1 - p, 3);
      setShown(Math.round(from + (value - from) * eased));
      if (p < 1) raf.current = requestAnimationFrame(step);
    };
    raf.current = requestAnimationFrame(step);
    return () => {
      if (raf.current !== null) cancelAnimationFrame(raf.current);
      raf.current = null;
    };
  }, [value, reduceMotion, fade]);

  return (
    <Animated.Text
      style={[numberStyle, { color, opacity: fade }]}
      maxFontSizeMultiplier={1.3}
      accessibilityElementsHidden
      importantForAccessibility="no"
    >
      {shown}
    </Animated.Text>
  );
}

export { numberStyle as dayCountTextStyle };
