import 'package:flutter/widgets.dart';

/// Type system: Instrument Serif (display) + Archivo (UI).
///
/// Both families are bundled in `pubspec.yaml`, so a weight is selected with a
/// real font file rather than being synthesised.
abstract final class FontFamily {
  static const display = 'InstrumentSerif';
  static const ui = 'Archivo';
}

/// Archivo at [size] / [weight], with optional tracking and line height.
///
/// `height` in Flutter is a multiplier of the font size, which is exactly what
/// the CSS `line-height: 1.3` values in the handoff mean.
TextStyle ui(
  double size, {
  FontWeight weight = FontWeight.w400,
  Color? color,
  double? height,
  double? letterSpacing,
}) {
  return TextStyle(
    fontFamily: FontFamily.ui,
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}

/// Instrument Serif at [size], with the design's line-height/tracking pairs.
TextStyle display(
  double size, {
  Color? color,
  double? height,
  double? letterSpacing,
}) {
  return TextStyle(
    fontFamily: FontFamily.display,
    fontSize: size,
    fontWeight: FontWeight.w400,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}

/// The overline used for every small uppercase label in the design
/// (date, sheet titles): 11pt / 700 / 0.16em / uppercase.
///
/// The text itself is uppercased at the call site — Flutter has no
/// `text-transform`, and Turkish casing needs the locale-aware helper anyway.
TextStyle overline({Color? color}) => ui(
      11,
      weight: FontWeight.w700,
      color: color,
      letterSpacing: 11 * 0.16,
    );
