import React from 'react';
import { Platform, Pressable, StyleSheet, Text, View } from 'react-native';
import { BlurView } from 'expo-blur';
import type { Tab } from '../domain/types';
import { color, layout, space } from '../theme/tokens';
import { ui } from '../theme/typography';
import { GridIcon, TimelineIcon } from './icons';

const TABS: Array<{ key: Tab; label: string }> = [
  { key: 'cards', label: 'Kartlar' },
  { key: 'time', label: 'Zaman tüneli' },
];

type Props = {
  value: Tab;
  onChange: (t: Tab) => void;
  bottomInset: number;
};

/** MD3 navigation bar / HIG tab bar, over a translucent blurred base. */
export function TabBar({ value, onChange, bottomInset }: Props) {
  const height = layout.tabBarContentHeight + bottomInset;

  return (
    <View style={[styles.root, { height, paddingBottom: bottomInset }]}>
      <BlurView intensity={Platform.OS === 'android' ? 40 : 28} tint="light" style={StyleSheet.absoluteFill} />
      <View style={styles.tint} />
      <View style={styles.row}>
        {TABS.map((t) => {
          const active = t.key === value;
          const tint = active ? color.primary : color.outline;
          return (
            <Pressable
              key={t.key}
              onPress={() => onChange(t.key)}
              accessibilityRole="tab"
              accessibilityState={{ selected: active }}
              accessibilityLabel={t.label}
              style={styles.item}
            >
              <View style={styles.icon}>
                {t.key === 'cards' ? (
                  <GridIcon color={tint} active={active} />
                ) : (
                  <TimelineIcon color={tint} active={active} />
                )}
              </View>
              <Text style={[styles.label, { color: tint }]} maxFontSizeMultiplier={1.2}>
                {t.label}
              </Text>
            </Pressable>
          );
        })}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  root: {
    position: 'absolute',
    left: 0,
    right: 0,
    bottom: 0,
    zIndex: 5,
    borderTopWidth: StyleSheet.hairlineWidth,
    borderTopColor: color.tabBarHairline,
    overflow: 'hidden',
  },
  tint: { ...StyleSheet.absoluteFill, backgroundColor: color.tabBarBase, pointerEvents: 'none' },
  row: { flexDirection: 'row', alignItems: 'flex-start', paddingTop: 9 },
  item: { flex: 1, alignItems: 'center', gap: 3, paddingBottom: 4 },
  icon: { height: 24, alignItems: 'center', justifyContent: 'center' },
  label: { ...ui(10.5, 600), letterSpacing: 10.5 * 0.01 },
});
