import React from 'react';
import { StyleSheet, Text, View } from 'react-native';
import Animated, { FadeInDown } from 'react-native-reanimated';
import { color, space } from '../theme/tokens';
import { display, ui } from '../theme/typography';

/** Shown when there is nothing to display — no cards, or none are overdue. */
export function EmptyState({ onlyLate, reduceMotion }: { onlyLate: boolean; reduceMotion: boolean }) {
  const body = onlyLate
    ? 'Geciken hiçbir şey yok — nadir bir gün.'
    : 'Henüz bir kart yok. Aşağıdaki düğmeyle ilk kartını ekle.';

  const content = (
    <>
      <Text style={styles.title} maxFontSizeMultiplier={1.3}>
        Burada kimse yok.
      </Text>
      <Text style={styles.body} maxFontSizeMultiplier={1.4}>
        {body}
      </Text>
    </>
  );

  if (reduceMotion) return <View style={styles.root}>{content}</View>;

  return (
    <Animated.View entering={FadeInDown.duration(300).withInitialValues({ transform: [{ translateY: 8 }] })} style={styles.root}>
      {content}
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  root: { marginVertical: 56, marginHorizontal: space.s14, alignItems: 'center' },
  title: { ...display(25, 25 * 1.16), color: color.onSurface, textAlign: 'center' },
  body: {
    ...ui(13, 400),
    lineHeight: 13 * 1.5,
    color: color.onSurfaceVariant,
    marginTop: space.s8,
    textAlign: 'center',
  },
});
