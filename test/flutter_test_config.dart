import 'dart:async';
import 'dart:ui';

import 'package:kac_gun_oldu/l10n/strings.dart';

/// Runs before every test in `test/`, including the subdirectories.
///
/// The app follows the phone's language unless someone picks one, and a host
/// machine running in English would otherwise flip the whole suite to the
/// English copy. Pinning the device locale keeps the assertions on the
/// Turkish originals; the English side has tests of its own that switch to it
/// explicitly.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  debugDeviceLocale = const Locale('tr');
  applyLang(AppLang.system);
  await testMain();
}
