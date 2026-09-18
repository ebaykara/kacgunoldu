import React, { useRef } from 'react';
import { Animated, Easing, Pressable, StyleSheet, Text } from 'react-native';
import { color, elevation, motion, radius, space } from '../theme/tokens';
import { ui } from '../theme/typography';
import { PlusIcon } from './icons';

const EMPHASIZED = Easing.bezier(...motion.emphasized);

/** "Yeni kart" — MD3 extended FAB / HIG prominent bottom-trailing button. */
export function Fab({ onPress, bottom }: { onPress: () => void; bottom: number }) {
  const press = useRef(new Animated.Value(0)).current;

  const to = (v: number) =>
    Animated.timing(press, { toValue: v, duration: motion.press, easing: EMPHASIZED, useNativeDriver: true }).start();

  return (
    <Animated.View
      style={[
        styles.wrap,
        elevation.fab,
        { bottom, transform: [{ scale: press.interpolate({ inputRange: [0, 1], outputRange: [1, 0.96] }) }] },
      ]}
    >
      <Pressable
        onPress={onPress}
        onPressIn={() => to(1)}
        onPressOut={() => to(0)}
        accessibilityRole="button"
        accessibilityLabel="Yeni kart"
        style={styles.fab}
      >
        <PlusIcon color={color.onPrimary} />
        <Text style={styles.label} maxFontSizeMultiplier={1.3}>
          Yeni kart
        </Text>
      </Pressable>
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  wrap: { position: 'absolute', right: space.s18, borderRadius: radius.fab, zIndex: 6 },
  fab: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: space.s8,
    paddingVertical: space.s16,
    paddingHorizontal: space.s20,
    borderRadius: radius.fab,
    backgroundColor: color.primary,
  },
  label: { ...ui(14, 600), color: color.onPrimary },
});
