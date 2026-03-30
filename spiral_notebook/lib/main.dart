import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:spiral_notebook/app_state.dart';
import 'package:spiral_notebook/firebase_options.dart';
import 'package:spiral_notebook/routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bool firebaseEnabled = await _initializeFirebase();
  runApp(MyApp(appState: SpiralAppState(firebaseEnabled: firebaseEnabled)));
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    widget.appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Nexi: Study Gacha',
          themeMode: widget.appState.themeMode,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF5DAFA3),
              primary: const Color(0xFF5DAFA3),
              secondary: const Color(0xFF7D90C8),
              surface: const Color(0xFFF7FAF8),
            ),
            scaffoldBackgroundColor: const Color(0xFFF0F4F2),
            appBarTheme: const AppBarTheme(
              centerTitle: false,
              backgroundColor: Colors.transparent,
              foregroundColor: Color(0xFF20303A),
              elevation: 0,
            ),
            cardTheme: CardThemeData(
              color: const Color(0xFFFBFDFC),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              margin: EdgeInsets.zero,
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              brightness: Brightness.dark,
              seedColor: const Color(0xFF78C3B8),
              primary: const Color(0xFF78C3B8),
              secondary: const Color(0xFF9AACE7),
              surface: const Color(0xFF162028),
            ),
            scaffoldBackgroundColor: const Color(0xFF0C141A),
            appBarTheme: const AppBarTheme(
              centerTitle: false,
              backgroundColor: Colors.transparent,
              foregroundColor: Color(0xFFE7F0ED),
              elevation: 0,
            ),
            cardTheme: CardThemeData(
              color: const Color(0xFF162028),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              margin: EdgeInsets.zero,
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
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
