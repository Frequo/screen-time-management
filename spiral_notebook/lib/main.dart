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
  void dispose() {
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
          title: 'Spiral Notebook',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFE96B2D),
              primary: const Color(0xFFE96B2D),
              secondary: const Color(0xFF0F9D8A),
              surface: const Color(0xFFFFFBF6),
            ),
            scaffoldBackgroundColor: const Color(0xFFF7F0E4),
            appBarTheme: const AppBarTheme(
              centerTitle: false,
              backgroundColor: Colors.transparent,
              foregroundColor: Color(0xFF1F2933),
              elevation: 0,
            ),
            cardTheme: CardThemeData(
              color: const Color(0xFFFDFBF8),
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
}
