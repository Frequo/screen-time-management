import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spiral_notebook/app_state.dart';
import 'package:spiral_notebook/main.dart';
import 'package:spiral_notebook/routes.dart';
import 'package:spiral_notebook/screens/cutscenescreen.dart';

void main() {
  testWidgets('app enters the main shell from login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp(appState: SpiralAppState()));

    expect(find.text('Focugacha'), findsOneWidget);
    expect(find.text('Sign in to Focugacha'), findsOneWidget);

    final SpiralAppState loggedInState = SpiralAppState()
      ..isLoggedIn = true
      ..playerName = 'Andrew';

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(MyApp(appState: loggedInState));
    await tester.pump();

    expect(find.text('Backpack'), findsOneWidget);
  });

  testWidgets('next reveal advances through a 10-pull cutscene', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final SpiralAppState appState = SpiralAppState();
    final List<GameCharacter> characters = appState.roster.take(10).toList();

    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (RouteSettings settings) =>
            onGenerateAppRoute(settings, appState),
        home: Builder(
          builder: (BuildContext context) {
            return TextButton(
              onPressed: () => Navigator.pushNamed(
                context,
                '/cutscene',
                arguments: CutsceneArgs(
                  characters: characters,
                  currentIndex: 0,
                  allowSkip: true,
                ),
              ),
              child: const Text('Start pull'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Start pull'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pump();

    expect(find.text(characters.first.name), findsOneWidget);
    expect(find.text('Pull 1 of 10'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Next reveal'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pump();

    expect(find.text(characters[1].name), findsOneWidget);
    expect(find.text('Pull 2 of 10'), findsOneWidget);
  });
}
