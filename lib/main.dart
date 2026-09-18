import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/home_screen.dart';
import 'state/card_store.dart';
import 'theme/tokens.dart';
import 'theme/typography.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The status bar sits over the warm page colour, so its icons have to be dark.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Color(0x00000000),
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: AppColor.surface,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final store = CardStore();
  await store.init();

  runApp(NeZamanApp(store: store));
}

class NeZamanApp extends StatelessWidget {
  const NeZamanApp({super.key, required this.store});

  final CardStore store;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ne Zaman?',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: FontFamily.ui,
        scaffoldBackgroundColor: AppColor.surface,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColor.primary,
          brightness: Brightness.light,
          primary: AppColor.primary,
          onPrimary: AppColor.onPrimary,
          surface: AppColor.surface,
          onSurface: AppColor.onSurface,
        ),
      ),
      builder: (context, child) {
        // Honour the system text size, but cap it: the card grid is two fixed
        // columns with a 58pt display number, and past ~1.3x the layout has
        // nowhere left to give.
        return MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.3,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: Scaffold(
        // The home screen paints its own background and manages its own
        // insets, so the scaffold stays out of the way.
        backgroundColor: AppColor.surface,
        body: HomeScreen(store: store),
      ),
    );
  }
}
