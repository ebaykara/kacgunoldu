import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kac_gun_oldu/theme/system_bars.dart';
import 'package:kac_gun_oldu/theme/tokens.dart';

Widget app() => MaterialApp(
      builder: (context, child) => SystemBarsRegion(child: child!),
      home: const Scaffold(body: Text('ana ekran')),
    );

void main() {
  tearDown(() {
    launchPhase.value = true;
    AppColor.current = kiremit;
  });

  testWidgets('MaterialApp\'s black navigation bar never wins', (tester) async {
    // MaterialApp sets SystemUiOverlayStyle.dark (black navigation bar) on
    // every build; the app's region must override it after each frame.
    await tester.pumpWidget(app());
    await tester.pump();
    final style = SystemChrome.latestStyle!;
    expect(style.systemNavigationBarColor, isNot(const Color(0xFF000000)));
    expect(style.systemNavigationBarColor, kiremit.launchColor);
  });

  testWidgets('after the opening, the bars take the theme\'s page colour', (tester) async {
    await tester.pumpWidget(app());
    launchPhase.value = false;
    await tester.pump();
    await tester.pump();
    expect(SystemChrome.latestStyle!.systemNavigationBarColor, kiremit.surface);
    expect(SystemChrome.latestStyle!.systemNavigationBarIconBrightness, Brightness.dark);
  });

  testWidgets('a theme change keeps the bar in the new theme, not black', (tester) async {
    await tester.pumpWidget(app());
    launchPhase.value = false;
    await tester.pump();

    // What CardStore.setTheme does: switch the palette, rebuild everything.
    AppColor.current = paletteById('gece');
    await tester.pumpWidget(Container());
    await tester.pumpWidget(app());
    await tester.pump();

    final style = SystemChrome.latestStyle!;
    expect(style.systemNavigationBarColor, paletteById('gece').surface);
    expect(style.systemNavigationBarIconBrightness, Brightness.light);
  });
}
