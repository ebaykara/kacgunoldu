import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import {
  Animated,
  BackHandler,
  Easing,
  Keyboard,
  KeyboardEvent,
  PanResponder,
  Platform,
  Pressable,
  StyleSheet,
  View,
} from 'react-native';
import { color, elevation, motion, radius, space } from '../theme/tokens';

const DECELERATE = Easing.bezier(...motion.decelerate);

type Props = {
  visible: boolean;
  onClose: () => void;
  /** Lift the panel above the software keyboard (create sheet). */
  avoidKeyboard?: boolean;
  bottomInset: number;
  reduceMotion: boolean;
  children: React.ReactNode;
};

/**
 * The shared sheet shell — MD3 modal bottom sheet / HIG sheet at a medium
 * detent with a grabber.
 *
 * Dismisses on scrim tap, on drag-down, and on the Android back gesture.
 */
export function Sheet({ visible, onClose, avoidKeyboard = false, bottomInset, reduceMotion, children }: Props) {
  const [mounted, setMounted] = useState(visible);
  const [height, setHeight] = useState(0);
  const [keyboard, setKeyboard] = useState(0);

  const t = useRef(new Animated.Value(0)).current; // 0 = closed, 1 = open
  const drag = useRef(new Animated.Value(0)).current; // extra downward offset while dragging
  const heightRef = useRef(0);
  heightRef.current = height;

  useEffect(() => {
    if (visible) setMounted(true);
  }, [visible]);

  useEffect(() => {
    if (!mounted) return;
    if (visible && height === 0) return; // wait for the first layout pass

    const anim = Animated.timing(t, {
      toValue: visible ? 1 : 0,
      duration: reduceMotion ? 0 : visible ? motion.sheetIn : 220,
      easing: DECELERATE,
      useNativeDriver: true,
    });
    anim.start(({ finished }) => {
      if (finished && !visible) {
        setMounted(false);
        setHeight(0);
        drag.setValue(0);
      }
    });
    return () => anim.stop();
  }, [visible, mounted, height, reduceMotion, t, drag]);

  useEffect(() => {
    if (!mounted || !avoidKeyboard) return;
    const show = (e: KeyboardEvent) => setKeyboard(e.endCoordinates.height);
    const hide = () => setKeyboard(0);
    const s = Keyboard.addListener(Platform.OS === 'ios' ? 'keyboardWillShow' : 'keyboardDidShow', show);
    const h = Keyboard.addListener(Platform.OS === 'ios' ? 'keyboardWillHide' : 'keyboardDidHide', hide);
    return () => {
      s.remove();
      h.remove();
    };
  }, [mounted, avoidKeyboard]);

  const requestClose = useCallback(() => {
    Keyboard.dismiss();
    onClose();
  }, [onClose]);

  useEffect(() => {
    if (!mounted || !visible) return;
    const sub = BackHandler.addEventListener('hardwareBackPress', () => {
      requestClose();
      return true;
    });
    return () => sub.remove();
  }, [mounted, visible, requestClose]);

  const pan = useMemo(
    () =>
      PanResponder.create({
        onMoveShouldSetPanResponder: (_e, g) => g.dy > 6 && Math.abs(g.dy) > Math.abs(g.dx),
        onPanResponderMove: (_e, g) => drag.setValue(Math.max(0, g.dy)),
        onPanResponderRelease: (_e, g) => {
          const far = g.dy > Math.max(80, heightRef.current * 0.3);
          if (far || g.vy > 0.8) {
            requestClose();
          } else {
            Animated.timing(drag, {
              toValue: 0,
              duration: 180,
              easing: DECELERATE,
              useNativeDriver: true,
            }).start();
          }
        },
        onPanResponderTerminate: () => drag.setValue(0),
      }),
    [drag, requestClose, heightRef],
  );

  if (!mounted) return null;

  // 103% of the panel height, matching the mock's off-screen start position.
  const closedOffset = height ? height * 1.03 : 1000;
  const translateY = Animated.add(
    t.interpolate({ inputRange: [0, 1], outputRange: [closedOffset, 0] }),
    drag,
  );

  return (
    <View style={styles.host}>
      <Animated.View style={[styles.scrim, { opacity: t }]}>
        <Pressable
          style={StyleSheet.absoluteFill}
          onPress={requestClose}
          accessibilityRole="button"
          accessibilityLabel="Kapat"
        />
      </Animated.View>

      <Animated.View
        {...pan.panHandlers}
        onLayout={(e) => {
          const h = e.nativeEvent.layout.height;
          if (h > 0 && Math.abs(h - heightRef.current) > 0.5) setHeight(h);
        }}
        style={[
          styles.panel,
          elevation.sheet,
          {
            // Mock pads 32pt; keep that floor but clear the home indicator.
            paddingBottom: Math.max(32, bottomInset + space.s12),
            bottom: keyboard,
            opacity: height ? 1 : 0,
            transform: [{ translateY }],
          },
        ]}
      >
        <View style={styles.grabber} />
        {children}
      </Animated.View>
    </View>
  );
}

const styles = StyleSheet.create({
  host: { ...StyleSheet.absoluteFill, zIndex: 9, pointerEvents: 'box-none' },
  scrim: { ...StyleSheet.absoluteFill, backgroundColor: color.scrim },
  panel: {
    position: 'absolute',
    left: 0,
    right: 0,
    zIndex: 10,
    backgroundColor: color.surfaceBright,
    borderTopLeftRadius: radius.sheet,
    borderTopRightRadius: radius.sheet,
    paddingTop: space.s14,
    paddingHorizontal: space.s20,
  },
  grabber: {
    width: 34,
    height: 4,
    borderRadius: radius.grabber,
    backgroundColor: color.outlineSheet,
    alignSelf: 'center',
    marginBottom: space.s16,
  },
});
