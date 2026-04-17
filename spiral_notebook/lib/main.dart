import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:spiral_notebook/app_state.dart';
import 'package:spiral_notebook/firebase_options.dart';
import 'package:spiral_notebook/routes.dart';
import 'package:spiral_notebook/services/focus_ambient_audio.dart';
import 'package:spiral_notebook/theme/app_palette.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bool firebaseEnabled = await _initializeFirebase();
  runApp(MyApp(appState: SpiralAppState(firebaseEnabled: firebaseEnabled)));
}

class _NoStretchScrollBehavior extends MaterialScrollBehavior {
  const _NoStretchScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

Future<bool> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return true;
  } on UnsupportedError {
    return false;
  } on FirebaseException {
    return false;
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.appState});

  final SpiralAppState appState;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final FocusAmbientAudioController _focusAmbientAudioController;

  @override
  void initState() {
    super.initState();
    _focusAmbientAudioController = FocusAmbientAudioController(
      appState: widget.appState,
    );
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    _focusAmbientAudioController.dispose();
    widget.appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (BuildContext context, Widget? child) {
        final AppAccentStyle accentStyle = widget.appState.accentStyle;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Nexi: Study Gacha',
          scrollBehavior: const _NoStretchScrollBehavior(),
          themeMode: widget.appState.themeMode,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              brightness: Brightness.light,
              seedColor: accentStyle.lightPrimary,
              primary: accentStyle.lightPrimary,
              onPrimary: Colors.white,
              secondary: accentStyle.lightSecondary,
              onSecondary: AppPalette.ink,
              tertiary: AppPalette.tangerine,
              onTertiary: Colors.white,
              error: Color(0xFFB62318),
              onError: Colors.white,
              surface: AppPalette.card,
              onSurface: AppPalette.ink,
              surfaceContainerHighest: Color(0xFFFFF1B8),
              onSurfaceVariant: AppPalette.inkMuted,
              outline: AppPalette.line,
            ),
            scaffoldBackgroundColor: AppPalette.page,
            appBarTheme: const AppBarTheme(
              centerTitle: false,
              backgroundColor: Colors.transparent,
              foregroundColor: AppPalette.ink,
              elevation: 0,
            ),
            cardTheme: CardThemeData(
              color: AppPalette.card,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              margin: EdgeInsets.zero,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.72),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: AppPalette.line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: AppPalette.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: accentStyle.lightPrimary,
                  width: 1.5,
                ),
              ),
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                backgroundColor: accentStyle.lightPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppPalette.ink,
                side: BorderSide(color: accentStyle.lightSecondary),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            segmentedButtonTheme: SegmentedButtonThemeData(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith<Color?>((
                  Set<WidgetState> states,
                ) {
                  if (states.contains(WidgetState.selected)) {
                    return AppPalette.sun;
                  }
                  return Colors.white.withValues(alpha: 0.64);
                }),
                foregroundColor: const WidgetStatePropertyAll<Color>(
                  AppPalette.ink,
                ),
                side: const WidgetStatePropertyAll<BorderSide>(
                  BorderSide(color: AppPalette.line),
                ),
              ),
            ),
            chipTheme: ChipThemeData(
              backgroundColor: Colors.white.withValues(alpha: 0.68),
              selectedColor: AppPalette.mint.withValues(alpha: 0.22),
              secondarySelectedColor: AppPalette.mint.withValues(alpha: 0.22),
              side: const BorderSide(color: AppPalette.line),
              labelStyle: const TextStyle(color: AppPalette.ink),
              secondaryLabelStyle: const TextStyle(color: AppPalette.ink),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: Colors.white.withValues(alpha: 0.82),
              indicatorColor: AppPalette.sun,
              labelTextStyle: const WidgetStatePropertyAll<TextStyle>(
                TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              brightness: Brightness.dark,
              seedColor: accentStyle.darkPrimary,
              primary: accentStyle.darkPrimary,
              onPrimary: Colors.white,
              secondary: accentStyle.darkSecondary,
              onSecondary: AppPalette.ink,
              tertiary: AppPalette.tangerine,
              onTertiary: Colors.white,
              error: Color(0xFFFF7B73),
              onError: AppPalette.night,
              surface: AppPalette.nightSurface,
              onSurface: Color(0xFFF4FBFF),
              surfaceContainerHighest: Color(0xFF113450),
              onSurfaceVariant: AppPalette.nightMuted,
              outline: Color(0xFF1A4666),
            ),
            scaffoldBackgroundColor: AppPalette.night,
            appBarTheme: const AppBarTheme(
              centerTitle: false,
              backgroundColor: Colors.transparent,
              foregroundColor: Color(0xFFF4FBFF),
              elevation: 0,
            ),
            cardTheme: CardThemeData(
              color: AppPalette.nightSurface,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              margin: EdgeInsets.zero,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Color(0xFF1A4666)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Color(0xFF1A4666)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: accentStyle.darkPrimary,
                  width: 1.5,
                ),
              ),
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                backgroundColor: accentStyle.darkPrimary,
                foregroundColor: AppPalette.ink,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFF4FBFF),
                side: BorderSide(color: accentStyle.darkSecondary),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            segmentedButtonTheme: SegmentedButtonThemeData(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith<Color?>((
                  Set<WidgetState> states,
                ) {
                  if (states.contains(WidgetState.selected)) {
                    return AppPalette.tangerine;
                  }
                  return Colors.white.withValues(alpha: 0.06);
                }),
                foregroundColor: const WidgetStatePropertyAll<Color>(
                  Color(0xFFF4FBFF),
                ),
                side: const WidgetStatePropertyAll<BorderSide>(
                  BorderSide(color: Color(0xFF1A4666)),
                ),
              ),
            ),
            chipTheme: ChipThemeData(
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              selectedColor: AppPalette.sky.withValues(alpha: 0.22),
              secondarySelectedColor: AppPalette.sky.withValues(alpha: 0.22),
              side: const BorderSide(color: Color(0xFF1A4666)),
              labelStyle: const TextStyle(color: Color(0xFFF4FBFF)),
              secondaryLabelStyle: const TextStyle(color: Color(0xFFF4FBFF)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: AppPalette.nightSurface,
              indicatorColor: AppPalette.tangerine,
              labelTextStyle: const WidgetStatePropertyAll<TextStyle>(
                TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          initialRoute: widget.appState.isLoggedIn ? '/app' : '/login',
          onGenerateRoute: (RouteSettings settings) =>
              onGenerateAppRoute(settings, widget.appState),
        );
      },
    );
  }

  late final WidgetsBindingObserver _lifecycleObserver = _AppLifecycleObserver(
    onBackgrounded: widget.appState.pauseFocusSession,
  );
}

class _AppLifecycleObserver with WidgetsBindingObserver {
  _AppLifecycleObserver({required this.onBackgrounded});

  final VoidCallback onBackgrounded;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        onBackgrounded();
      case AppLifecycleState.inactive:
      case AppLifecycleState.resumed:
        break;
    }
  }
}
