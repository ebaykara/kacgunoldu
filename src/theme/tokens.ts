/**
 * Design tokens — "Ne Zaman?" (last-time tracker)
 *
 * Values are transcribed verbatim from the hifi handoff (`Ne Zaman v2.dc.html`
 * + README). Names follow the Material 3 role vocabulary used in the handoff's
 * token table so the mapping stays one-to-one.
 */

export const color = {
  primary: '#B8492A',
  onPrimary: '#FFF3EA',
  primaryContainer: '#FFE2D5',
  onPrimaryContainer: '#3A0C00',
  primaryContainerHover: '#FFD3C1',
  primaryDim: '#C98A6B',
  ringOnPrimary: '#FFD7C4',

  tertiary: '#6B8F4E',
  tertiaryContainer: '#E7F0DB',
  onTertiaryContainer: '#1F2A14',

  surface: '#FBF5F0',
  surfaceBright: '#FFFDFA',
  surfaceContainer: '#F6EFE9',
  surfaceContainerHover: '#EEE4DC',

  onSurface: '#241F1B',
  onSurfaceVariant: '#87786C',
  onSurfaceMuted: '#7A6A5E',

  outline: '#A2907F',
  outlineVariant: '#E6D9CF',
  outlineSheet: '#EADFD6',
  outlineTimeline: '#EEE0D6',

  inverseSurface: '#332B25',
  inverseOnSurface: '#F6ECE4',
  inverseAccent: '#FFB598',

  scrim: 'rgba(36,31,27,0.36)',

  /** Text on the overdue pill. */
  onOverduePill: '#7A4227',
  /** Hairline above the bottom tab bar. */
  tabBarHairline: 'rgba(36,31,27,0.08)',
  /** Translucent tab bar base (sits over a blur). */
  tabBarBase: 'rgba(251,245,240,0.82)',
} as const;

/** 4pt base scale, exactly the steps used by the design. */
export const space = {
  xs: 4,
  s6: 6,
  s7: 7,
  s8: 8,
  s12: 12,
  s14: 14,
  s15: 15,
  s16: 16,
  s18: 18,
  s20: 20,
  s22: 22,
} as const;

export const radius = {
  grabber: 9,
  dayCell: 13,
  item: 16,
  field: 18,
  tile: 18,
  fab: 20,
  button: 19,
  card: 26,
  sheet: 28,
  pill: 999,
} as const;

/**
 * Elevation, transcribed verbatim from the design's CSS box-shadows.
 *
 * React Native's `boxShadow` takes the CSS string form, so the multi-layer
 * shadows with negative spread survive intact instead of being approximated by
 * an iOS shadow triple. (Android renders these from API 28 up.)
 */
export const elevation = {
  card: { boxShadow: '0px 1px 0px rgba(36,31,27,0.05), 0px 12px 24px -20px rgba(36,31,27,0.6)' },
  cardLate: { boxShadow: '0px 10px 24px -14px rgba(140,52,26,0.9), 0px 1px 2px rgba(36,31,27,0.1)' },
  fab: { boxShadow: '0px 12px 26px -12px rgba(140,52,26,0.85), 0px 2px 5px rgba(36,31,27,0.14)' },
  sheet: { boxShadow: '0px -24px 60px -24px rgba(36,31,27,0.5)' },
  snackbar: { boxShadow: '0px 14px 30px -14px rgba(36,31,27,0.7)' },
  timelineItem: { boxShadow: '0px 1px 0px rgba(36,31,27,0.05), 0px 8px 18px -16px rgba(36,31,27,0.5)' },
} as const;

/** Motion durations (ms) and the cubic-bezier control points behind them. */
export const motion = {
  press: 160,
  hover: 160,
  ring: 500,
  countdown: 620,
  sheetIn: 340,
  scrim: 200,
  snackbar: 260,
  halo: 750,
  pop: 600,
  /** cubic-bezier(.2,.8,.2,1) — press / pop / reflow */
  emphasized: [0.2, 0.8, 0.2, 1] as const,
  /** cubic-bezier(.2,.9,.2,1) — sheet + snackbar entry */
  decelerate: [0.2, 0.9, 0.2, 1] as const,
} as const;

/** Snackbar auto-dismiss windows. The record window is also the undo window. */
export const snackbarTimeout = {
  record: 4200,
  create: 3200,
} as const;

/** Fixed geometry lifted from the mock. */
export const layout = {
  /** Bottom tab bar height above the home-indicator inset. */
  tabBarContentHeight: 50,
  /** Scroll padding that clears FAB + tab bar. */
  gridBottomPadding: 150,
  cardMinHeight: 168,
  cardGap: 12,
  ringSize: 52,
  ringHoleSize: 40,
  /** HIG / MD3 minimum touch target. */
  minTouchTarget: 44,
} as const;
