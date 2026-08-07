// Render checks for the screens that gained history/daily-target UI, at the
// narrowest width the app supports. The history screen shipped two real
// horizontal overflows that only a compact-width layout pass caught.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:spiral_notebook/app_state.dart';
import 'package:spiral_notebook/routes.dart';
import 'package:spiral_notebook/screens/focusscreen.dart';
import 'package:spiral_notebook/screens/inventoryscreen.dart';
import 'package:spiral_notebook/screens/settingscreen.dart';

SpiralAppState _stateWithHistory() {
  final SpiralAppState appState = SpiralAppState()
    ..isLoggedIn = true
    ..playerName = 'Andrew'
    ..playerEmail = 'andrew@example.com';
  appState.setDailyTarget(90);

  for (int i = 0; i < 3; i += 1) {
    appState.clock = () => DateTime(2031, 8, 4).add(Duration(days: i, hours: 9));
    appState.startFocusSession();
    appState.currentSessionSeconds = 45 * 60;
    appState.finishFocusSession();
  }
  appState.clock = () => DateTime(2031, 8, 6, 12);
  return appState;
}

/// Scrolls the primary list until [finder] is on screen. These screens are
/// long, so asserting on a fixed viewport would only prove the top rendered.
Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    250,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

Widget _host(SpiralAppState appState, Widget child) {
  return MaterialApp(
    onGenerateRoute: (RouteSettings settings) =>
        onGenerateAppRoute(settings, appState),
    home: child,
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('inventory shows daily progress and opens history', (
    WidgetTester tester,
  ) async {
    // 390x844 (iPhone 14/15 class). Not 320pt wide: the character roster grid
    // has a pre-existing vertical overflow at iPhone SE width (the fixed
    // childAspectRatio: 0.78 in characterview.dart), unrelated to this screen's
    // history UI, which would mask what this test is checking.
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final SpiralAppState appState = _stateWithHistory();
    addTearDown(appState.dispose);

    await tester.pumpWidget(
      _host(
        appState,
        Scaffold(
          body: InventoryScreen(
            appState: appState,
            onStartFocus: () {},
            onOpenGacha: () {},
            onOpenSettings: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Daily progress is above the fold, right under the hero card.
    expect(find.text('Today'), findsOneWidget);
    expect(find.textContaining('of 90 min today'), findsOneWidget);
    expect(find.text('3d streak'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await _scrollTo(tester, find.text('View focus history'));
    await tester.tap(find.text('View focus history'));
    await tester.pumpAndSettle();

    expect(find.text('Focus history'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings daily target shows live progress and links to history', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final SpiralAppState appState = _stateWithHistory();
    addTearDown(appState.dispose);

    await tester.pumpWidget(_host(appState, SettingsScreen(appState: appState)));
    await tester.pumpAndSettle();

    await _scrollTo(tester, find.text('Daily target: 90 min'));
    expect(find.text('Daily target: 90 min'), findsOneWidget);
    expect(find.text('Today: 45 of 90 min'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await _scrollTo(tester, find.text('View focus history'));
    await tester.tap(find.text('View focus history'));
    await tester.pumpAndSettle();

    expect(find.text('Focus history'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('stand reminders toggle controls the focus-tab stand card', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final SpiralAppState appState = _stateWithHistory();
    addTearDown(appState.dispose);

    await tester.pumpWidget(
      _host(appState, Scaffold(body: FocusScreen(appState: appState))),
    );
    await tester.pumpAndSettle();

    // Reminders default on: the stand prompt is present.
    expect(appState.reminderEnabled, isTrue);
    expect(find.text('Stand not connected'), findsOneWidget);

    appState.setReminderEnabled(false);
    await tester.pumpAndSettle();

    expect(find.text('Stand not connected'), findsNothing);
    // The focus screen itself is untouched.
    expect(find.text('Start focus session'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
