import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:spiral_notebook/app_state.dart';
import 'package:spiral_notebook/screens/historyscreen.dart';

void _logSession(
  SpiralAppState appState,
  DateTime completedAt, {
  int minutes = 30,
}) {
  appState.clock = () => completedAt;
  appState.startFocusSession();
  appState.currentSessionSeconds = minutes * 60;
  appState.finishFocusSession();
}

Widget _wrap(SpiralAppState appState) {
  return MaterialApp(home: HistoryScreen(appState: appState));
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('renders the empty state before any session is logged', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final SpiralAppState appState = SpiralAppState();
    addTearDown(appState.dispose);

    await tester.pumpWidget(_wrap(appState));
    await tester.pumpAndSettle();

    expect(find.text('Focus history'), findsOneWidget);
    expect(find.text('No sessions yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders daily progress, streak, chart, and the session log', (
    WidgetTester tester,
  ) async {
    // Tall surface so the whole scroll view is laid out at once and the session
    // log at the bottom is reachable by the finders.
    await tester.binding.setSurfaceSize(const Size(430, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final SpiralAppState appState = SpiralAppState();
    addTearDown(appState.dispose);

    appState.setDailyTarget(90);
    appState.setDifficulty(AppDifficulty.highSchool);
    _logSession(appState, DateTime(2031, 8, 5, 10), minutes: 30);
    _logSession(appState, DateTime(2031, 8, 6, 9), minutes: 45);
    appState.clock = () => DateTime(2031, 8, 6, 12);

    await tester.pumpWidget(_wrap(appState));
    await tester.pumpAndSettle();

    // Today card: 45 of a 90 minute target.
    expect(find.textContaining('of 90 min today'), findsOneWidget);
    expect(find.textContaining('45 minutes left'), findsOneWidget);

    // "2" appears three times: current streak, best streak, sessions logged —
    // all three are 2 for this fixture.
    expect(find.text('2'), findsNWidgets(3));
    expect(find.text('day streak'), findsOneWidget);
    expect(find.text('best streak'), findsOneWidget);
    expect(find.text('Sessions logged'), findsOneWidget);

    expect(find.text('Last 7 days'), findsOneWidget);
    expect(find.text('Session log'), findsOneWidget);
    expect(find.textContaining('2 most recent sessions'), findsOneWidget);

    // Both sessions appear, with their bit payouts.
    expect(find.textContaining('Today,'), findsOneWidget);
    expect(find.textContaining('Yesterday,'), findsOneWidget);
    expect(find.text('+265 bits'), findsOneWidget); // 45 * 5 + 15 + 25
    expect(find.text('+165 bits'), findsOneWidget); // 30 * 5 + 15

    // Weekly chart plots both days.
    expect(find.text('45'), findsWidgets);
    expect(find.text('30'), findsOneWidget);

    // No overflow or paint exceptions anywhere in the tree.
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the target-met badge once the daily goal is reached', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final SpiralAppState appState = SpiralAppState();
    addTearDown(appState.dispose);

    appState.setDailyTarget(30);
    _logSession(appState, DateTime(2031, 8, 6, 9), minutes: 45);
    appState.clock = () => DateTime(2031, 8, 6, 12);

    await tester.pumpWidget(_wrap(appState));
    await tester.pumpAndSettle();

    expect(find.text('Target met'), findsOneWidget);
    expect(find.textContaining('Daily target reached'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders on a compact phone width without overflowing', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final SpiralAppState appState = SpiralAppState();
    addTearDown(appState.dispose);

    for (int i = 0; i < 5; i += 1) {
      _logSession(appState, DateTime(2031, 8, 2).add(Duration(days: i)));
    }
    appState.clock = () => DateTime(2031, 8, 6, 12);

    await tester.pumpWidget(_wrap(appState));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
