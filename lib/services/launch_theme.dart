import 'package:flutter/services.dart';

const _channel = MethodChannel('kac_gun_oldu/launch');

/// Tells Android which colour theme to use for the system launch screen next
/// time (`LaunchTheme.<Name>` in the Android styles, Android 13+).
/// Best-effort: on other platforms, in tests, or on older Android there is
/// nothing to call and it keeps its default colour.
Future<void> applyLaunchTheme(String themeId) async {
  if (themeId.isEmpty) return;
  final name = themeId[0].toUpperCase() + themeId.substring(1);
  try {
    await _channel.invokeMethod<void>('setTheme', name);
  } catch (_) {}
}

/// Tells the native opening animation (`MainActivity`) that the app has drawn
/// its first frame. It lets the animation finish, fades away, and this
/// completes once it is gone. Elsewhere it completes at once.
Future<void> appReady() async {
  try {
    await _channel.invokeMethod<void>('ready');
  } catch (_) {}
}
