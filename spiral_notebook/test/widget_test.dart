import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spiral_notebook/app_state.dart';
import 'package:spiral_notebook/main.dart';

void main() {
  testWidgets('app enters the main shell from login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp(appState: SpiralAppState()));

    expect(find.text('Nexi'), findsOneWidget);
    expect(find.text('Sign in to Nexi'), findsOneWidget);

    final SpiralAppState loggedInState = SpiralAppState()
      ..isLoggedIn = true
      ..playerName = 'Andrew';

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(MyApp(appState: loggedInState));
    await tester.pump();

    expect(find.text('Backpack'), findsOneWidget);
  });
}
