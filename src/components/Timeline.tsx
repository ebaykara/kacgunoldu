import React from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { color, elevation, radius, space } from '../theme/tokens';
import { display, ui } from '../theme/typography';

export type TimelineGroup = {
  key: string;
  /** Day of month, e.g. `18`. */
  dom: number;
  /** Abbreviated month, e.g. `EYL`. */
  mon: string;
  /** `bugün` / `3 gün önce` / … */
  rel: string;
  items: string[];
};

/**
 * "Zaman tüneli" — what actually happened, newest first.
 * A rail with punched-through nodes; the gutter carries the date.
 */
export function Timeline({ groups }: { groups: TimelineGroup[] }) {
  return (
    <View style={styles.root}>
      {groups.map((g) => (
        <View key={g.key} style={styles.group}>
          <View style={styles.gutter}>
            <Text style={styles.dom} maxFontSizeMultiplier={1.3}>
              {g.dom}
            </Text>
            <Text style={styles.mon} maxFontSizeMultiplier={1.3}>
              {g.mon}
            </Text>
          </View>

          <View style={styles.rail}>
            <View style={styles.node} />
            <Text style={styles.rel} maxFontSizeMultiplier={1.3}>
              {g.rel}
            </Text>
            <View style={styles.items}>
              {g.items.map((it, i) => (
                <View key={`${g.key}-${i}`} style={[styles.item, elevation.timelineItem]}>
                  <Text style={styles.itemText} maxFontSizeMultiplier={1.4}>
                    {it}
                  </Text>
                </View>
              ))}
            </View>
          </View>
        </View>
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  root: { paddingTop: space.s6 },
  group: { flexDirection: 'row', gap: space.s14, paddingBottom: space.xs },
  gutter: { width: 58, paddingTop: 2, alignItems: 'flex-end' },
  dom: { ...display(22, 22), color: color.onSurface },
  mon: {
    ...ui(10, 700),
    letterSpacing: 10 * 0.1,
    textTransform: 'uppercase',
    color: color.outline,
    marginTop: 2,
  },
  rail: {
    flex: 1,
    minWidth: 0,
    borderLeftWidth: 1.5,
    borderLeftColor: color.outlineTimeline,
    paddingLeft: space.s16,
    paddingBottom: space.s22,
  },
  // 9pt dot with a 3pt ring of page colour, so it reads as punched through the
  // rail. Drawn as a 15pt bordered box centred on the rail (9 + 3 + 3).
  node: {
    position: 'absolute',
    left: -8.5,
    top: 3,
    width: 15,
    height: 15,
    borderRadius: 999,
    backgroundColor: color.primary,
    borderWidth: 3,
    borderColor: color.surface,
  },
  rel: { ...ui(11, 600), color: color.outline, marginBottom: space.s8 },
  items: { gap: space.s7 },
  item: {
    paddingVertical: space.s12,
    paddingHorizontal: space.s14,
    borderRadius: radius.item,
    backgroundColor: color.surfaceBright,
  },
  itemText: { ...ui(13, 600), color: color.onSurface, lineHeight: 13 * 1.3 },
});
