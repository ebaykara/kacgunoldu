import React, { useEffect, useRef } from 'react';
import { Animated, Easing, Pressable, StyleSheet, Text } from 'react-native';
import { color, elevation, motion, radius, space } from '../theme/tokens';
import { ui } from '../theme/typography';

const DECELERATE = Easing.bezier(...motion.decelerate);

type Props = {
  message: string;
  /** `Geri al` is only offered for records, never for card creation. */
  undoable: boolean;
  onUndo: () => void;
  bottom: number;
  reduceMotion: boolean;
};

/** MD3 snackbar with action / HIG toast with Undo. */
export function Snackbar({ message, undoable, onUndo, bottom, reduceMotion }: Props) {
  const t = useRef(new Animated.Value(reduceMotion ? 1 : 0)).current;

  useEffect(() => {
    if (reduceMotion) {
      t.setValue(1);
      return;
    }
    t.setValue(0);
    const anim = Animated.timing(t, {
      toValue: 1,
      duration: motion.snackbar,
      easing: DECELERATE,
      useNativeDriver: true,
    });
    anim.start();
    return () => anim.stop();
  }, [message, reduceMotion, t]);

  return (
    <Animated.View
      accessibilityLiveRegion="polite"
      style={[
        styles.root,
        elevation.snackbar,
        {
          bottom,
          opacity: t,
          transform: [
            { translateY: t.interpolate({ inputRange: [0, 1], outputRange: [14, 0] }) },
            { scale: t.interpolate({ inputRange: [0, 1], outputRange: [0.96, 1] }) },
          ],
        },
      ]}
    >
      <Text style={styles.message} numberOfLines={2} maxFontSizeMultiplier={1.4}>
        {message}
      </Text>
      {undoable ? (
        <Pressable onPress={onUndo} accessibilityRole="button" accessibilityLabel="Geri al" style={styles.action}>
          <Text style={styles.actionText} maxFontSizeMultiplier={1.3}>
            Geri al
          </Text>
        </Pressable>
      ) : null}
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  root: {
    position: 'absolute',
    left: space.s14,
    right: space.s14,
    zIndex: 8,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: space.s12,
    paddingVertical: 13,
    paddingLeft: space.s18,
    paddingRight: 10,
    borderRadius: radius.item,
    backgroundColor: color.inverseSurface,
  },
  message: { ...ui(13, 500), color: color.inverseOnSurface, flexShrink: 1, lineHeight: 13 * 1.3 },
  action: { paddingVertical: space.s8, paddingHorizontal: space.s14, borderRadius: 999 },
  actionText: { ...ui(13, 700), color: color.inverseAccent },
});
