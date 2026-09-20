import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/strings.dart';
import 'legal/font_licenses.dart';
import 'screens/home_screen.dart';
import 'services/home_widgets.dart';
import 'services/reminders.dart';
import 'services/launch_theme.dart';
import 'state/card_store.dart';
import 'theme/system_bars.dart';
import 'theme/tokens.dart';
import 'theme/typography.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicenses();

  // The system bars are left alone while the native launch view is up: it
  // sets them itself (see LaunchScreen.kt), and a style sent from here would
  // land on the engine's first frame, mid launch - the navigation bar
  // flashed black. The theme's own bars come in once the launch view is gone.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Loads the saved theme too.
  final store = CardStore(reminders: LocalReminders(), homeWidgets: PlatformHomeWidgets());
  await store.init();

  runApp(KacGunOlduApp(store: store));

  // The native opening animation lifts once the first frame is up, then the
  // theme's own system bars replace the launch-coloured ones.
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await appReady();
    launchPhase.value = false;
    applySystemBars();
  });
}

class KacGunOlduApp extends StatelessWidget {
  const KacGunOlduApp({super.key, required this.store});

  final CardStore store;

  Route<void> _homeRoute() => MaterialPageRoute(
    settings: const RouteSettings(name: Navigator.defaultRouteName),
    builder: (_) => Scaffold(
      backgroundColor: AppColor.surface,
      body: HomeScreen(store: store),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: S.appName,
      debugShowCheckedModeBanner: false,
      // `null` under AppLang.system, so Flutter resolves the device's own
      // locale for the calendar and the system dialogs — the same fallback
      // order our own strings use (see `applyLang`).
      locale: appLocale,
      supportedLocales: supportedLangLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: FontFamily.ui,
        scaffoldBackgroundColor: AppColor.surface,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColor.primary,
          brightness: AppColor.current.isDark ? Brightness.dark : Brightness.light,
          primary: AppColor.primary,
          onPrimary: AppColor.onPrimary,
          surface: AppColor.surface,
          onSurface: AppColor.onSurface,
        ),
        // iOS gets its edge swipe back; Android keeps its own motion.
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.android: FadeForwardsPageTransitionsBuilder(
              backgroundColor: AppColor.surface,
            ),
          },
        ),
        datePickerTheme: DatePickerThemeData(
          backgroundColor: AppColor.surfaceBright,
          headerBackgroundColor: AppColor.primary,
          headerForegroundColor: AppColor.onPrimary,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.sheet)),
          dayStyle: ui(14, weight: FontWeight.w600),
          todayBorder: BorderSide(color: AppColor.primary, width: 1.5),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: AppColor.surfaceBright,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.sheet)),
          titleTextStyle: ui(18, weight: FontWeight.w700, color: AppColor.onSurface),
          contentTextStyle: ui(14, color: AppColor.onSurfaceVariant, height: 1.45),
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: AppColor.primary,
          selectionColor: AppColor.primaryContainerHover,
          selectionHandleColor: AppColor.primary,
        ),
      ),
      builder: (context, child) {
        // Honour the system text size, but cap it: the card grid is two fixed
        // columns with a 58pt display number, and past ~1.3x the layout has
        // nowhere left to give.
        return SystemBarsRegion(
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.3,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      // The opening animation is a native view on top of this (MainActivity).
      //
      // Always starts here, whatever the platform's initial route: a home
      // screen widget opens the app with a link (kacgunoldu://app/card/<id>)
      // that CardStore turns into "open this card", not a named route.
      onGenerateInitialRoutes: (_) => [_homeRoute()],
      onGenerateRoute: (settings) =>
          settings.name == Navigator.defaultRouteName ? _homeRoute() : null,
    );
  }
}
