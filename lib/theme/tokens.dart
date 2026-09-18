import 'package:flutter/widgets.dart';

/// Design tokens — "Ne Zaman?" (last-time tracker)
///
/// Values are transcribed verbatim from the hifi handoff (`Ne Zaman v2.dc.html`
/// + README). Names follow the Material 3 role vocabulary used in the handoff's
/// token table so the mapping stays one-to-one.
abstract final class AppColor {
  static const primary = Color(0xFFB8492A);
  static const onPrimary = Color(0xFFFFF3EA);
  static const primaryContainer = Color(0xFFFFE2D5);
  static const onPrimaryContainer = Color(0xFF3A0C00);
  static const primaryContainerHover = Color(0xFFFFD3C1);
  static const primaryDim = Color(0xFFC98A6B);
  static const ringOnPrimary = Color(0xFFFFD7C4);

  static const tertiary = Color(0xFF6B8F4E);
  static const tertiaryContainer = Color(0xFFE7F0DB);
  static const onTertiaryContainer = Color(0xFF1F2A14);

  static const surface = Color(0xFFFBF5F0);
  static const surfaceBright = Color(0xFFFFFDFA);
  static const surfaceContainer = Color(0xFFF6EFE9);
  static const surfaceContainerHover = Color(0xFFEEE4DC);

  static const onSurface = Color(0xFF241F1B);
  static const onSurfaceVariant = Color(0xFF87786C);
  static const onSurfaceMuted = Color(0xFF7A6A5E);

  static const outline = Color(0xFFA2907F);
  static const outlineVariant = Color(0xFFE6D9CF);
  static const outlineSheet = Color(0xFFEADFD6);
  static const outlineTimeline = Color(0xFFEEE0D6);

  static const inverseSurface = Color(0xFF332B25);
  static const inverseOnSurface = Color(0xFFF6ECE4);
  static const inverseAccent = Color(0xFFFFB598);

  static const scrim = Color(0x5C241F1B); // rgba(36,31,27,.36)

  /// Text on the overdue pill.
  static const onOverduePill = Color(0xFF7A4227);

  /// Hairline above the bottom tab bar.
  static const tabBarHairline = Color(0x14241F1B); // rgba(36,31,27,.08)

  /// Translucent tab bar base (sits over a blur).
  static const tabBarBase = Color(0xD1FBF5F0); // rgba(251,245,240,.82)
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

  static const List<BoxShadow> cardLate = [
    BoxShadow(color: Color(0xE68C341A), offset: Offset(0, 10), blurRadius: 24, spreadRadius: -14),
    BoxShadow(color: Color(0x1A241F1B), offset: Offset(0, 1), blurRadius: 2),
  ];

  static const List<BoxShadow> fab = [
    BoxShadow(color: Color(0xD98C341A), offset: Offset(0, 12), blurRadius: 26, spreadRadius: -12),
    BoxShadow(color: Color(0x24241F1B), offset: Offset(0, 2), blurRadius: 5),
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
  static const List<BoxShadow> dragging = [
    BoxShadow(color: Color(0x668C341A), offset: Offset(0, 18), blurRadius: 34, spreadRadius: -12),
    BoxShadow(color: Color(0x24241F1B), offset: Offset(0, 4), blurRadius: 8),
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
