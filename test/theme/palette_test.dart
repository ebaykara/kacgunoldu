import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:kac_gun_oldu/theme/tokens.dart';

/// WCAG contrast ratio between two opaque colours.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  test('Kiremit is the handoff palette, value for value', () {
    expect(palettes.first.id, 'kiremit');
    expect(kiremit.primary, const Color(0xFFB8492A));
    expect(kiremit.surface, const Color(0xFFFBF5F0));
    expect(kiremit.onOverduePill, const Color(0xFF7A4227));
  });

  test('theme ids are unique and unknown ids fall back to Kiremit', () {
    final ids = palettes.map((p) => p.id).toList();
    expect(ids.toSet().length, ids.length);
    expect(paletteById('yok-boyle-tema').id, 'kiremit');
    expect(paletteById(null).id, 'kiremit');
    expect(paletteById('gece').isDark, isTrue);
  });

  for (final p in palettes) {
    test('${p.name}: text stays readable on every surface it sits on', () {
      // Body text and card ink: AAA.
      expect(contrast(p.onSurface, p.surface), greaterThanOrEqualTo(7));
      expect(contrast(p.onSurface, p.surfaceBright), greaterThanOrEqualTo(7));
      expect(contrast(p.onPrimaryContainer, p.primaryContainer), greaterThanOrEqualTo(7));
      expect(contrast(p.onTertiaryContainer, p.tertiaryContainer), greaterThanOrEqualTo(7));
      // The overdue card's big number and the filled buttons: AA.
      expect(contrast(p.onPrimary, p.primary), greaterThanOrEqualTo(4.5));
      // Secondary text (dates, captions): AA for large-ish text.
      expect(contrast(p.onSurfaceVariant, p.surface), greaterThanOrEqualTo(3));
    });
  }

  group('launch screen colours', () {
    // Android can't read Dart, so each theme's launch colour is written into
    // the Android resources as well. They must not drift apart.
    String hex(Color c) =>
        c.toARGB32().toRadixString(16).substring(2).toUpperCase();
    const res = 'android/app/src/main/res';

    test('colors.xml has a launch colour per palette, the same as the Dart one', () {
      final xml = File('$res/values/colors.xml').readAsStringSync();
      for (final p in palettes) {
        final m = RegExp('name="launch_${p.id}">#([0-9A-Fa-f]{6})<').firstMatch(xml);
        expect(m, isNotNull, reason: '${p.id} missing');
        expect(m!.group(1)!.toUpperCase(), hex(p.launchColor), reason: p.id);
      }
    });

    for (final dir in ['values-v31', 'values-night-v31']) {
      test('$dir has a launch theme per palette pointing at its own colour', () {
        final xml = File('$res/$dir/styles.xml').readAsStringSync();
        for (final p in palettes) {
          final name = p.id[0].toUpperCase() + p.id.substring(1);
          final block = RegExp(
            'name="LaunchTheme\\.$name"[\\s\\S]*?'
            r'windowSplashScreenBackground">@color/launch_(\w+)<',
          ).firstMatch(xml);
          expect(block, isNotNull, reason: '${p.id} missing in $dir');
          expect(block!.group(1), p.id, reason: '${p.id} in $dir');
        }
      });
    }

    test('light themes avoid pale launch colours', () {
      // A pale launch colour gets inverted to dark grey by phones in dark mode.
      for (final p in palettes.where((p) => !p.isDark)) {
        expect(p.launchColor.computeLuminance(), lessThan(0.45), reason: p.id);
      }
    });
  });
}
