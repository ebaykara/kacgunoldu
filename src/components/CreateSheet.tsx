import React, { useRef, useState } from 'react';
import { Animated, Easing, Pressable, StyleSheet, Text, TextInput, View } from 'react-native';
import { color, radius, space } from '../theme/tokens';
import { display, ui } from '../theme/typography';

const EASE = Easing.out(Easing.ease);

/** The things people most often lose track of — one tap fills the field. */
const SUGGESTIONS = [
  'çarşafları değiştirdim',
  'bitkileri suladım',
  'çamaşır yıkadım',
  'spor yaptım',
  'anneme telefon ettim',
  'diş hekimine gittim',
  'saçımı kestirdim',
  'arabanın yağını değiştirdim',
  'banyoyu temizledim',
  'ilaç aldım',
];

type Props = {
  value: string;
  onChange: (v: string) => void;
  /** Add the card, then open the record sheet to pick a date. */
  onAddAndPickDate: () => void;
  /** Add the card with today already recorded. */
  onAddToday: () => void;
};

/** "Neyi takip edelim?" — the create sheet. */
export function CreateSheet({ value, onChange, onAddAndPickDate, onAddToday }: Props) {
  const [focused, setFocused] = useState(false);
  const press = useRef(new Animated.Value(0)).current;
  const disabled = value.trim().length === 0;

  const to = (v: number) =>
    Animated.timing(press, { toValue: v, duration: 140, easing: EASE, useNativeDriver: true }).start();

  return (
    <View>
      <Text style={styles.title} maxFontSizeMultiplier={1.3} accessibilityRole="header">
        Neyi takip edelim?
      </Text>

      <TextInput
        value={value}
        onChangeText={onChange}
        onFocus={() => setFocused(true)}
        onBlur={() => setFocused(false)}
        placeholder="örn. çarşafları değiştirdim"
        placeholderTextColor={color.outline}
        style={[styles.field, focused && styles.fieldFocused]}
        autoCapitalize="none"
        autoCorrect
        returnKeyType="done"
        onSubmitEditing={() => {
          if (!disabled) onAddAndPickDate();
        }}
        accessibilityLabel="Kart adı"
        maxFontSizeMultiplier={1.3}
      />

      <Text style={styles.helper} maxFontSizeMultiplier={1.4}>
        Geçmiş zaman yaz — kart bir cümle gibi okunur.
      </Text>

      <View style={styles.chips}>
        {SUGGESTIONS.map((s) => (
          <Pressable
            key={s}
            onPress={() => onChange(s)}
            accessibilityRole="button"
            accessibilityLabel={s}
            style={styles.chip}
          >
            <Text style={styles.chipText} maxFontSizeMultiplier={1.3}>
              {s}
            </Text>
          </Pressable>
        ))}
      </View>

      <Animated.View
        style={{ transform: [{ scale: press.interpolate({ inputRange: [0, 1], outputRange: [1, 0.98] }) }] }}
      >
        <Pressable
          onPress={onAddAndPickDate}
          onPressIn={() => to(1)}
          onPressOut={() => to(0)}
          disabled={disabled}
          accessibilityRole="button"
          accessibilityState={{ disabled }}
          accessibilityLabel="Ekle ve tarih seç"
          style={[styles.primary, disabled && styles.disabled]}
        >
          <Text style={styles.primaryText} maxFontSizeMultiplier={1.3}>
            Ekle ve tarih seç
          </Text>
        </Pressable>
      </Animated.View>

      <Pressable
        onPress={onAddToday}
        disabled={disabled}
        accessibilityRole="button"
        accessibilityState={{ disabled }}
        accessibilityLabel="Bugün itibariyle ekle"
        style={[styles.secondary, disabled && styles.disabled]}
      >
        <Text style={styles.secondaryText} maxFontSizeMultiplier={1.3}>
          Bugün itibariyle ekle
        </Text>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  title: { ...display(26, 26 * 1.14), color: color.onSurface },
  field: {
    width: '100%',
    marginTop: space.s14,
    marginBottom: space.s8,
    padding: space.s16,
    borderWidth: 1.5,
    borderColor: color.outlineSheet,
    borderRadius: radius.field,
    backgroundColor: color.surfaceBright,
    ...ui(15, 600),
    color: color.onSurface,
  },
  fieldFocused: { borderColor: color.primary },
  helper: { ...ui(11.5, 400), color: color.outline, marginBottom: space.s14 },
  chips: { flexDirection: 'row', flexWrap: 'wrap', gap: space.s7, marginBottom: space.s18 },
  chip: {
    paddingVertical: 9,
    paddingHorizontal: space.s14,
    borderRadius: 999,
    borderWidth: 1,
    borderColor: color.outlineSheet,
  },
  chipText: { ...ui(12.5, 600), color: color.onSurfaceMuted },
  primary: {
    padding: 17,
    borderRadius: radius.button,
    backgroundColor: color.primary,
    alignItems: 'center',
  },
  primaryText: { ...ui(14.5, 700), color: color.onPrimary },
  secondary: {
    padding: space.s16,
    marginTop: space.s8,
    borderRadius: radius.button,
    backgroundColor: color.surfaceContainer,
    alignItems: 'center',
  },
  secondaryText: { ...ui(14.5, 600), color: color.onSurfaceMuted },
  disabled: { opacity: 0.45 },
});
