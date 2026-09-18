import 'package:flutter/widgets.dart';

/// Design tokens — "Kaç Gün Oldu?" (last-time tracker)
///
/// Values are transcribed verbatim from the hifi handoff (`Ne Zaman v2.dc.html`
/// + README). Names follow the Material 3 role vocabulary used in the handoff's
/// token table so the mapping stays one-to-one.
///
/// Colours come from the selected [Palette]. `kiremit` is the handoff's own
/// terracotta, value for value; every other theme fills the same roles.
class Palette {
  const Palette({
    required this.id,
    required this.name,
    required this.isDark,
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.primaryContainerHover,
    required this.primaryDim,
    required this.ringOnPrimary,
    required this.primaryLight,
    required this.tertiary,
    required this.tertiaryContainer,
    required this.onTertiaryContainer,
    required this.surface,
    required this.surfaceBright,
    required this.surfaceContainer,
    required this.surfaceContainerHover,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.onSurfaceMuted,
    required this.outline,
    required this.outlineVariant,
    required this.outlineSheet,
    required this.outlineTimeline,
    required this.inverseSurface,
    required this.inverseOnSurface,
    required this.inverseAccent,
    required this.onOverduePill,
    required this.shadowTint,
    required this.launchColor,
  });

  /// A theme from its key tones; the in-between roles are blended the way
  /// Kiremit's are, so each theme only has to be designed once.
  factory Palette.derive({
    required String id,
    required String name,
    bool isDark = false,
    required Color primary,
    required Color onPrimary,
    required Color primaryContainer,
    required Color onPrimaryContainer,
    required Color primaryDim,
    required Color ringOnPrimary,
    required Color tertiary,
    required Color tertiaryContainer,
    required Color onTertiaryContainer,
    required Color surface,
    required Color surfaceBright,
    required Color surfaceContainer,
    required Color onSurface,
    required Color onSurfaceVariant,
    required Color outline,
    required Color outlineVariant,
    required Color inverseSurface,
    required Color inverseAccent,
    required Color onOverduePill,
    required Color shadowTint,
    required Color launchColor,
  }) {
    Color mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;
    return Palette(
      id: id,
      name: name,
      isDark: isDark,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      primaryContainerHover: mix(primaryContainer, primary, 0.14),
      primaryDim: primaryDim,
      ringOnPrimary: ringOnPrimary,
      primaryLight: mix(primary, isDark ? onSurface : surfaceBright, 0.18),
      tertiary: tertiary,
      tertiaryContainer: tertiaryContainer,
      onTertiaryContainer: onTertiaryContainer,
      surface: surface,
      surfaceBright: surfaceBright,
      surfaceContainer: surfaceContainer,
      surfaceContainerHover: mix(surfaceContainer, onSurface, 0.06),
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      onSurfaceMuted: mix(onSurfaceVariant, onSurface, 0.12),
      outline: outline,
      outlineVariant: outlineVariant,
      outlineSheet: mix(outlineVariant, surface, 0.2),
      outlineTimeline: mix(outlineVariant, surface, 0.35),
      inverseSurface: inverseSurface,
      inverseOnSurface: mix(surface, inverseSurface, 0.06),
      inverseAccent: inverseAccent,
      onOverduePill: onOverduePill,
      shadowTint: shadowTint,
      launchColor: launchColor,
    );
  }

  final String id;

  /// Shown in the theme picker.
  final String name;

  /// Dark surfaces: the system bar icons flip to light.
  final bool isDark;

  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color primaryContainerHover;
  final Color primaryDim;
  final Color ringOnPrimary;

  /// A lighter step of [primary] for highlights (avatar gradient, pot rim).
  final Color primaryLight;

  final Color tertiary;
  final Color tertiaryContainer;
  final Color onTertiaryContainer;
  final Color surface;
  final Color surfaceBright;
  final Color surfaceContainer;
  final Color surfaceContainerHover;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color onSurfaceMuted;
  final Color outline;
  final Color outlineVariant;
  final Color outlineSheet;
  final Color outlineTimeline;
  final Color inverseSurface;
  final Color inverseOnSurface;
  final Color inverseAccent;
  final Color onOverduePill;

  /// The hue coloured shadows (late card, FAB, buttons) are cast in.
  final Color shadowTint;

  /// The launch screen's background while this theme is chosen (a vivid
  /// mid-tone, or the surface itself for a dark theme). The Android side
  /// keeps a copy per theme in `values-v31/styles.xml` — `palette_test.dart`
  /// checks the two agree. Light launch colours are avoided on purpose: a
  /// phone in dark mode inverts them into a dark grey screen.
  final Color launchColor;
}

/// The handoff's own theme — the default.
const kiremit = Palette(
  id: 'kiremit',
  name: 'Kiremit',
  isDark: false,
  primary: Color(0xFFB8492A),
  onPrimary: Color(0xFFFFF3EA),
  primaryContainer: Color(0xFFFFE2D5),
  onPrimaryContainer: Color(0xFF3A0C00),
  primaryContainerHover: Color(0xFFFFD3C1),
  primaryDim: Color(0xFFC98A6B),
  ringOnPrimary: Color(0xFFFFD7C4),
  primaryLight: Color(0xFFD06A48),
  tertiary: Color(0xFF6B8F4E),
  tertiaryContainer: Color(0xFFE7F0DB),
  onTertiaryContainer: Color(0xFF1F2A14),
  surface: Color(0xFFFBF5F0),
  surfaceBright: Color(0xFFFFFDFA),
  surfaceContainer: Color(0xFFF6EFE9),
  surfaceContainerHover: Color(0xFFEEE4DC),
  onSurface: Color(0xFF241F1B),
  onSurfaceVariant: Color(0xFF87786C),
  onSurfaceMuted: Color(0xFF7A6A5E),
  outline: Color(0xFFA2907F),
  outlineVariant: Color(0xFFE6D9CF),
  outlineSheet: Color(0xFFEADFD6),
  outlineTimeline: Color(0xFFEEE0D6),
  inverseSurface: Color(0xFF332B25),
  inverseOnSurface: Color(0xFFF6ECE4),
  inverseAccent: Color(0xFFFFB598),
  onOverduePill: Color(0xFF7A4227),
  shadowTint: Color(0xFF8C341A),
  launchColor: Color(0xFFF85D4F),
);

/// Every theme, in picker order. The derived ones blend, so they are built
/// once at first use rather than as constants.
final List<Palette> palettes = [
  kiremit,
  Palette.derive(
    id: 'okyanus',
    name: 'Okyanus',
    primary: const Color(0xFF2F5D8A),
    onPrimary: const Color(0xFFF0F6FC),
    primaryContainer: const Color(0xFFD8E6F5),
    onPrimaryContainer: const Color(0xFF0A2138),
    primaryDim: const Color(0xFF7C9BB8),
    ringOnPrimary: const Color(0xFFC7DBEF),
    tertiary: const Color(0xFF3F8F7F),
    tertiaryContainer: const Color(0xFFD9EFEA),
    onTertiaryContainer: const Color(0xFF0F2A25),
    surface: const Color(0xFFF4F7FA),
    surfaceBright: const Color(0xFFFCFDFE),
    surfaceContainer: const Color(0xFFEAF0F5),
    onSurface: const Color(0xFF1A2129),
    onSurfaceVariant: const Color(0xFF6B7885),
    outline: const Color(0xFF8A97A4),
    outlineVariant: const Color(0xFFD7E0E8),
    inverseSurface: const Color(0xFF26303A),
    inverseAccent: const Color(0xFF9CC7F0),
    onOverduePill: const Color(0xFF2C4A68),
    shadowTint: const Color(0xFF1E3F60),
    launchColor: const Color(0xFF3D7FC1),
  ),
  Palette.derive(
    id: 'orman',
    name: 'Orman',
    primary: const Color(0xFF3E6B48),
    onPrimary: const Color(0xFFF1F7EF),
    primaryContainer: const Color(0xFFDCEBD9),
    onPrimaryContainer: const Color(0xFF10261A),
    primaryDim: const Color(0xFF86A48A),
    ringOnPrimary: const Color(0xFFCFE3CC),
    tertiary: const Color(0xFFB08530),
    tertiaryContainer: const Color(0xFFF5EBD3),
    onTertiaryContainer: const Color(0xFF33260A),
    surface: const Color(0xFFF6F6F0),
    surfaceBright: const Color(0xFFFDFDF9),
    surfaceContainer: const Color(0xFFEDEEE5),
    onSurface: const Color(0xFF1E221C),
    onSurfaceVariant: const Color(0xFF727868),
    outline: const Color(0xFF939A89),
    outlineVariant: const Color(0xFFDDE0D4),
    inverseSurface: const Color(0xFF2B3129),
    inverseAccent: const Color(0xFFA9D3A6),
    onOverduePill: const Color(0xFF2E5236),
    shadowTint: const Color(0xFF22402A),
    launchColor: const Color(0xFF4C9A5C),
  ),
  Palette.derive(
    id: 'lavanta',
    name: 'Lavanta',
    primary: const Color(0xFF6B4FA0),
    onPrimary: const Color(0xFFF6F2FD),
    primaryContainer: const Color(0xFFE8E0F6),
    onPrimaryContainer: const Color(0xFF221338),
    primaryDim: const Color(0xFFA592C6),
    ringOnPrimary: const Color(0xFFDCD0F2),
    tertiary: const Color(0xFF4E8C7A),
    tertiaryContainer: const Color(0xFFDDEFE8),
    onTertiaryContainer: const Color(0xFF12291F),
    surface: const Color(0xFFF8F6FA),
    surfaceBright: const Color(0xFFFEFDFF),
    surfaceContainer: const Color(0xFFF0EDF4),
    onSurface: const Color(0xFF221F27),
    onSurfaceVariant: const Color(0xFF7A7285),
    outline: const Color(0xFF9A92A4),
    outlineVariant: const Color(0xFFE3DEEA),
    inverseSurface: const Color(0xFF2F2A36),
    inverseAccent: const Color(0xFFCDB8F5),
    onOverduePill: const Color(0xFF4A3571),
    shadowTint: const Color(0xFF3A2860),
    launchColor: const Color(0xFF8460D0),
  ),
  Palette.derive(
    id: 'gul',
    name: 'Gül',
    primary: const Color(0xFFB23A5E),
    onPrimary: const Color(0xFFFFF1F4),
    primaryContainer: const Color(0xFFFBDDE5),
    onPrimaryContainer: const Color(0xFF3D0718),
    primaryDim: const Color(0xFFCF8499),
    ringOnPrimary: const Color(0xFFFFD1DC),
    tertiary: const Color(0xFF5E8A5A),
    tertiaryContainer: const Color(0xFFE3EFDD),
    onTertiaryContainer: const Color(0xFF1A2A17),
    surface: const Color(0xFFFCF5F6),
    surfaceBright: const Color(0xFFFFFDFD),
    surfaceContainer: const Color(0xFFF6ECEE),
    onSurface: const Color(0xFF2A1E21),
    onSurfaceVariant: const Color(0xFF8A737A),
    outline: const Color(0xFFA68D94),
    outlineVariant: const Color(0xFFEBD9DE),
    inverseSurface: const Color(0xFF3A2A2F),
    inverseAccent: const Color(0xFFFFB1C4),
    onOverduePill: const Color(0xFF7A2A42),
    shadowTint: const Color(0xFF7A1F3B),
    launchColor: const Color(0xFFE0507B),
  ),
  Palette.derive(
    id: 'gece',
    name: 'Gece',
    isDark: true,
    primary: const Color(0xFFE07A55),
    onPrimary: const Color(0xFF2A0E03),
    primaryContainer: const Color(0xFF4A2618),
    onPrimaryContainer: const Color(0xFFFFDCCD),
    primaryDim: const Color(0xFFB0765A),
    ringOnPrimary: const Color(0xFF6E2A12),
    tertiary: const Color(0xFF9CC27A),
    tertiaryContainer: const Color(0xFF263320),
    onTertiaryContainer: const Color(0xFFDCEBCB),
    surface: const Color(0xFF171412),
    surfaceBright: const Color(0xFF231E1B),
    surfaceContainer: const Color(0xFF2C2622),
    onSurface: const Color(0xFFF3EAE2),
    onSurfaceVariant: const Color(0xFFB5A596),
    outline: const Color(0xFF8C7C6E),
    outlineVariant: const Color(0xFF3D352F),
    inverseSurface: const Color(0xFFEDE3DA),
    inverseAccent: const Color(0xFFB8492A),
    onOverduePill: const Color(0xFFFFB598),
    shadowTint: const Color(0xFF000000),
    launchColor: const Color(0xFF171412),
  ),
];

/// The theme with [id], or Kiremit for anything unknown.
Palette paletteById(String? id) =>
    palettes.firstWhere((p) => p.id == id, orElse: () => kiremit);

/// Every colour role, read from [current]. Getters rather than constants so
/// a theme switch reaches every screen.
abstract final class AppColor {
  /// Set through `CardStore.setTheme`, which also rebuilds the tree.
  static Palette current = kiremit;

  static Color get primary => current.primary;
  static Color get onPrimary => current.onPrimary;
  static Color get primaryContainer => current.primaryContainer;
  static Color get onPrimaryContainer => current.onPrimaryContainer;
  static Color get primaryContainerHover => current.primaryContainerHover;
  static Color get primaryDim => current.primaryDim;
  static Color get ringOnPrimary => current.ringOnPrimary;
  static Color get primaryLight => current.primaryLight;

  static Color get tertiary => current.tertiary;
  static Color get tertiaryContainer => current.tertiaryContainer;
  static Color get onTertiaryContainer => current.onTertiaryContainer;

  static Color get surface => current.surface;
  static Color get surfaceBright => current.surfaceBright;
  static Color get surfaceContainer => current.surfaceContainer;
  static Color get surfaceContainerHover => current.surfaceContainerHover;

  static Color get onSurface => current.onSurface;
  static Color get onSurfaceVariant => current.onSurfaceVariant;
  static Color get onSurfaceMuted => current.onSurfaceMuted;

  static Color get outline => current.outline;
  static Color get outlineVariant => current.outlineVariant;
  static Color get outlineSheet => current.outlineSheet;
  static Color get outlineTimeline => current.outlineTimeline;

  static Color get inverseSurface => current.inverseSurface;
  static Color get inverseOnSurface => current.inverseOnSurface;
  static Color get inverseAccent => current.inverseAccent;

  /// rgba(36,31,27,.36) in Kiremit; heavier over dark surfaces.
  static Color get scrim =>
      (current.isDark ? const Color(0xFF000000) : current.onSurface)
          .withValues(alpha: current.isDark ? 0.55 : 0.36);

  /// Text on the overdue pill.
  static Color get onOverduePill => current.onOverduePill;

  /// Hairline above the bottom tab bar — rgba(36,31,27,.08) in Kiremit.
  static Color get tabBarHairline => current.onSurface.withValues(alpha: 0.08);

  /// Translucent tab bar base (sits over a blur) — rgba(251,245,240,.82).
  static Color get tabBarBase => current.surface.withValues(alpha: 0.82);

  /// The theme's shadow hue at [alpha].
  static Color shadow(double alpha) => current.shadowTint.withValues(alpha: alpha);
}

/// 4pt base scale, exactly the steps used by the design.
abstract final class Space {
  static const double xs = 4;
  static const double s6 = 6;
  static const double s7 = 7;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s14 = 14;
  static const double s15 = 15;
  static const double s16 = 16;
  static const double s18 = 18;
  static const double s20 = 20;
  static const double s22 = 22;
}

abstract final class Radii {
  static const double grabber = 9;
  static const double dayCell = 13;
  static const double item = 16;
  static const double field = 18;
  static const double tile = 18;
  static const double fab = 20;
  static const double button = 19;
  static const double card = 26;
  static const double panel = 22;
  static const double sheet = 28;
  static const double pill = 999;
}

/// Elevation, transcribed from the design's CSS box-shadows. Flutter's
/// [BoxShadow] maps `blur` to `blurRadius` and the negative CSS spread to a
/// negative `spreadRadius`, so the multi-layer shadows survive intact.
abstract final class Elevation {
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0D241F1B), offset: Offset(0, 1), blurRadius: 0),
    BoxShadow(color: Color(0x99241F1B), offset: Offset(0, 12), blurRadius: 24, spreadRadius: -20),
  ];

  // The coloured shadows take the theme's hue (0x8C341A in Kiremit).
  static List<BoxShadow> get cardLate => [
    BoxShadow(color: AppColor.shadow(0.9), offset: const Offset(0, 10), blurRadius: 24, spreadRadius: -14),
    const BoxShadow(color: Color(0x1A241F1B), offset: Offset(0, 1), blurRadius: 2),
  ];

  static List<BoxShadow> get fab => [
    BoxShadow(color: AppColor.shadow(0.85), offset: const Offset(0, 12), blurRadius: 26, spreadRadius: -12),
    const BoxShadow(color: Color(0x24241F1B), offset: Offset(0, 2), blurRadius: 5),
  ];

  static List<BoxShadow> get button => [
    BoxShadow(color: AppColor.shadow(0.6), offset: const Offset(0, 10), blurRadius: 22, spreadRadius: -12),
    const BoxShadow(color: Color(0x1A241F1B), offset: Offset(0, 1), blurRadius: 2),
  ];

  static const List<BoxShadow> sheet = [
    BoxShadow(color: Color(0x80241F1B), offset: Offset(0, -24), blurRadius: 60, spreadRadius: -24),
  ];

  static const List<BoxShadow> snackbar = [
    BoxShadow(color: Color(0xB3241F1B), offset: Offset(0, 14), blurRadius: 30, spreadRadius: -14),
  ];

  static const List<BoxShadow> timelineItem = [
    BoxShadow(color: Color(0x0D241F1B), offset: Offset(0, 1), blurRadius: 0),
    BoxShadow(color: Color(0x80241F1B), offset: Offset(0, 8), blurRadius: 18, spreadRadius: -16),
  ];

  /// The lifted state while a card is being dragged.
  static List<BoxShadow> get dragging => [
    BoxShadow(color: AppColor.shadow(0.4), offset: const Offset(0, 18), blurRadius: 34, spreadRadius: -12),
    const BoxShadow(color: Color(0x24241F1B), offset: Offset(0, 4), blurRadius: 8),
  ];
}

/// Motion durations and the cubic-bezier curves behind them.
abstract final class Motion {
  static const press = Duration(milliseconds: 160);
  static const hover = Duration(milliseconds: 160);
  static const ring = Duration(milliseconds: 500);
  static const countdown = Duration(milliseconds: 620);
  static const sheetIn = Duration(milliseconds: 340);
  static const scrim = Duration(milliseconds: 200);
  static const snackbar = Duration(milliseconds: 260);
  static const halo = Duration(milliseconds: 750);
  static const pop = Duration(milliseconds: 600);
  static const swap = Duration(milliseconds: 260);

  /// cubic-bezier(.2,.8,.2,1) — press / pop / reflow
  static const emphasized = Cubic(0.2, 0.8, 0.2, 1);

  /// cubic-bezier(.2,.9,.2,1) — sheet + snackbar entry
  static const decelerate = Cubic(0.2, 0.9, 0.2, 1);
}

/// Snackbar auto-dismiss windows. The record window is also the undo window.
abstract final class SnackbarTimeout {
  static const record = Duration(milliseconds: 4200);
  static const create = Duration(milliseconds: 3200);
}

/// Fixed geometry lifted from the mock.
abstract final class Layout {
  /// Bottom tab bar height above the home-indicator inset.
  static const double tabBarContentHeight = 50;

  /// Scroll padding that clears FAB + tab bar.
  static const double gridBottomPadding = 150;
  static const double cardMinHeight = 168;
  static const double cardGap = 12;
  static const double ringSize = 52;
  static const double ringHoleSize = 40;

  /// HIG / MD3 minimum touch target.
  static const double minTouchTarget = 44;
}
