import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spiral_notebook/main.dart';

void main() {
  testWidgets('app enters the main shell from login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Spiral Notebook'), findsOneWidget);
    expect(find.text('Enter notebook'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Display name'),
      'Andrew',
    );
    await tester.tap(find.text('Enter notebook'));
    await tester.pumpAndSettle();

    expect(find.text('Base Camp'), findsWidgets);
    expect(find.text('Difficulty and rewards'), findsOneWidget);
  });
}
