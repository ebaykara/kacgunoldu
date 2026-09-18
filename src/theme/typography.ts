import { TextStyle } from 'react-native';

/**
 * Type system: Instrument Serif (display) + Archivo (UI).
 *
 * React Native cannot synthesise weights for bundled fonts, so a weight is
 * selected by picking the right family file rather than by `fontWeight`.
 */

export const fontFamily = {
  display: 'InstrumentSerif_400Regular',
  ui400: 'Archivo_400Regular',
  ui500: 'Archivo_500Medium',
  ui600: 'Archivo_600SemiBold',
  ui700: 'Archivo_700Bold',
  ui800: 'Archivo_800ExtraBold',
} as const;

export type UIWeight = 400 | 500 | 600 | 700 | 800;

const UI_FAMILY: Record<UIWeight, string> = {
  400: fontFamily.ui400,
  500: fontFamily.ui500,
  600: fontFamily.ui600,
  700: fontFamily.ui700,
  800: fontFamily.ui800,
};

/** Archivo at `size` / `weight`. */
export function ui(size: number, weight: UIWeight = 400): TextStyle {
  return { fontFamily: UI_FAMILY[weight], fontSize: size, fontWeight: undefined };
}

/** Instrument Serif at `size`, with the design's line-height/tracking pairs. */
export function display(size: number, lineHeight?: number, letterSpacing?: number): TextStyle {
  return {
    fontFamily: fontFamily.display,
    fontSize: size,
    ...(lineHeight !== undefined ? { lineHeight } : null),
    ...(letterSpacing !== undefined ? { letterSpacing } : null),
  };
}

/**
 * Overline used for every small uppercase label in the design
 * (date, sheet titles): 11pt / 700 / 0.16em / uppercase.
 */
export const overline: TextStyle = {
  ...ui(11, 700),
  letterSpacing: 11 * 0.16,
  textTransform: 'uppercase',
};
