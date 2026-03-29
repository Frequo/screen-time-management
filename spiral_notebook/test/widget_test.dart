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

    await tester.enterText(
      find.widgetWithText(TextField, 'Email'),
      'andrew@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Password'),
      'secret123',
    );
    await tester.tap(find.text('Sign in to Nexi'));
    await tester.pumpAndSettle();

    expect(find.text('Difficulty and rewards'), findsOneWidget);
  });
}
