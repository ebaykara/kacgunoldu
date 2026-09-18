import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kac_gun_oldu/app_info.dart';
import 'package:kac_gun_oldu/legal/legal_model.dart';
import 'package:kac_gun_oldu/legal/legal_text.dart';
import 'package:kac_gun_oldu/screens/legal_screen.dart';

void main() {
  test('appVersion matches pubspec.yaml', () {
    final line = File('pubspec.yaml')
        .readAsLinesSync()
        .firstWhere((l) => l.startsWith('version:'));
    expect(line.split(':')[1].trim().split('+').first, appVersion);
  });

  test('both documents are complete and name the contact', () {
    for (final d in [privacyPolicy, termsOfUse]) {
      expect(d.sections.length, greaterThan(8));
      expect(
        d.sections.last.blocks.any((b) => b.kind == LegalBlockKind.contact),
        isTrue,
        reason: d.title,
      );
    }
    expect(legalEmail, 'info@gezip.app');
  });

  test('the font licence text is bundled', () {
    expect(File('assets/fonts/OFL.txt').existsSync(), isTrue);
  });

  testWidgets('the privacy policy opens and scrolls', (tester) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: LegalScreen(doc: privacyPolicy))),
    );
    expect(find.text('Gizlilik Politikası'), findsOneWidget);
    expect(find.textContaining('1. Genel Bakış'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byType(SelectableText),
      500,
      scrollable: find.byType(Scrollable),
    );
    expect(find.byType(SelectableText), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
