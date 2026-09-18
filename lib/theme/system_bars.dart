import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'tokens.dart';

/// True while the native opening animation (MainActivity) still covers the
/// app. The bars stay in the launch colour until it is gone.
final launchPhase = ValueNotifier<bool>(true);

/// The status and navigation bars for right now: the launch colour with
/// light icons during the opening, then the theme's — dark icons over the
/// light themes' warm page colour, light icons over Gece.
SystemUiOverlayStyle systemBarsStyle() {
  final p = AppColor.current;
  if (launchPhase.value) {
    return SystemUiOverlayStyle(
      statusBarColor: const Color(0x00000000),
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: p.launchColor,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarContrastEnforced: false,
    );
  }
  final dark = p.isDark;
  return SystemUiOverlayStyle(
    statusBarColor: const Color(0x00000000),
    statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
    statusBarBrightness: dark ? Brightness.dark : Brightness.light,
    systemNavigationBarColor: p.surface,
    systemNavigationBarIconBrightness: dark ? Brightness.light : Brightness.dark,
    systemNavigationBarContrastEnforced: false,
  );
}

/// Applies [systemBarsStyle] at once. The lasting source of truth is
/// [SystemBarsRegion] at the root of the app — see there for why.
void applySystemBars() => SystemChrome.setSystemUIOverlayStyle(systemBarsStyle());

/// Holds the app's system bar style for every frame.
///
/// MaterialApp calls `SystemChrome.setSystemUIOverlayStyle` with
/// `SystemUiOverlayStyle.dark` whenever it builds — and that style has a
/// BLACK navigation bar. It made the bar flash black the moment the first
/// frame drew under the launch view, and replaced the theme's bar after every
/// theme change. An [AnnotatedRegion] over the whole app is applied by the
/// framework after each frame, after MaterialApp's call, so it always wins.
class SystemBarsRegion extends StatelessWidget {
  const SystemBarsRegion({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: launchPhase,
      builder: (context, _, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: systemBarsStyle(),
        child: child!,
      ),
      child: child,
    );
  }
}
