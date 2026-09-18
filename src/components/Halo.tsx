import React, { useEffect, useRef } from 'react';
import { Animated, Easing, StyleSheet } from 'react-native';
import Svg, { Defs, RadialGradient, Rect, Stop } from 'react-native-svg';
import { motion } from '../theme/tokens';

const SIZE = 200;

/**
 * The celebration disc: a soft puff of the tier's ring colour that expands out
 * of the card centre and fades. Clipped by the card's rounded box.
 */
export function Halo({ color, nonce }: { color: string; nonce: number }) {
  const t = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    t.setValue(0);
    const anim = Animated.timing(t, {
      toValue: 1,
      duration: motion.halo,
      easing: Easing.out(Easing.ease),
      useNativeDriver: true,
    });
    anim.start();
    return () => anim.stop();
  }, [nonce, t]);

  return (
    <Animated.View
      style={[
        styles.root,
        {
          opacity: t.interpolate({ inputRange: [0, 1], outputRange: [0.55, 0] }),
          transform: [{ scale: t.interpolate({ inputRange: [0, 1], outputRange: [0.55, 1.9] }) }],
        },
      ]}
    >
      <Svg width={SIZE} height={SIZE}>
        <Defs>
          <RadialGradient id="halo" cx="50%" cy="50%" r="50%">
            <Stop offset="0" stopColor={color} stopOpacity={1} />
            <Stop offset="0.68" stopColor={color} stopOpacity={0} />
          </RadialGradient>
        </Defs>
        <Rect x={0} y={0} width={SIZE} height={SIZE} fill="url(#halo)" />
      </Svg>
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  root: {
    position: 'absolute',
    left: '50%',
    top: '50%',
    width: SIZE,
    height: SIZE,
    marginLeft: -SIZE / 2,
    marginTop: -SIZE / 2,
    pointerEvents: 'none',
  },
});
