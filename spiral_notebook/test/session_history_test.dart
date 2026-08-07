import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:spiral_notebook/app_state.dart';

/// Runs one session of [minutes] that finishes at [completedAt].
///
/// Drives the real session path (start -> elapse -> finish) rather than
/// appending records directly, so what the tests assert is what the app
/// actually writes.
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('a completed session is recorded in history', () {
    final SpiralAppState appState = SpiralAppState();
    addTearDown(appState.dispose);

    appState.setDifficulty(AppDifficulty.highSchool); // 5 bits/min
    appState.setFocusTarget(25);
    _logSession(appState, DateTime(2026, 8, 6, 14, 30), minutes: 30);

    expect(appState.loggedSessionCount, 1);
    final FocusSessionRecord record = appState.sessionHistory.single;
    expect(record.wholeMinutes, 30);
    expect(record.bitsEarned, 165); // 30 * 5 + 15 (>=20 min bonus)
    expect(record.difficulty, AppDifficulty.highSchool);
    expect(record.targetMinutes, 25);
    // 30 minutes against a 25 minute target.
    expect(record.metTarget, isTrue);
  });

  test('sub-minute sessions are not logged', () {
    final SpiralAppState appState = SpiralAppState();
    addTearDown(appState.dispose);

    appState.clock = () => DateTime(2026, 8, 6, 9);
    appState.startFocusSession();
    appState.currentSessionSeconds = 45;
    appState.finishFocusSession();

    expect(appState.loggedSessionCount, 0);
    expect(appState.currentStreakDays, 0);
  });

  test('history is capped at the retention limit, newest first', () {
    final SpiralAppState appState = SpiralAppState();
    addTearDown(appState.dispose);

    final int overflow = SpiralAppState.sessionHistoryLimit + 10;
    for (int i = 0; i < overflow; i += 1) {
      // One session per day, walking forward in time.
      _logSession(appState, DateTime(2026, 1, 1).add(Duration(days: i)));
    }

    expect(appState.loggedSessionCount, SpiralAppState.sessionHistoryLimit);
    final List<FocusSessionRecord> history = appState.sessionHistory;
    // Newest first, and the oldest entries were the ones dropped.
    expect(history.first.completedAt.isAfter(history.last.completedAt), isTrue);
    expect(
      history.first.completedAt,
      DateTime(2026, 1, 1).add(Duration(days: overflow - 1)),
    );
  });

  group('daily totals', () {
    test('today only counts sessions from the current calendar day', () {
      final SpiralAppState appState = SpiralAppState();
      addTearDown(appState.dispose);

      _logSession(appState, DateTime(2026, 8, 5, 20), minutes: 60);
      _logSession(appState, DateTime(2026, 8, 6, 9), minutes: 25);
      _logSession(appState, DateTime(2026, 8, 6, 15), minutes: 35);

      appState.clock = () => DateTime(2026, 8, 6, 18);
      expect(appState.todayFocusMinutes, 60); // 25 + 35, not yesterday's 60
      expect(appState.totalFocusMinutes, 120); // lifetime still counts all
    });

    test('daily progress tracks the target instead of pinning at full', () {
      final SpiralAppState appState = SpiralAppState();
      addTearDown(appState.dispose);

      appState.setDailyTarget(90);
      _logSession(appState, DateTime(2026, 8, 6, 9), minutes: 45);
      appState.clock = () => DateTime(2026, 8, 6, 12);

      expect(appState.dailyProgressMinutes, 45);
      expect(appState.dailyProgress, closeTo(0.5, 1e-9));
      expect(appState.dailyMinutesRemaining, 45);
      expect(appState.isDailyTargetMet, isFalse);

      _logSession(appState, DateTime(2026, 8, 6, 13), minutes: 60);
      appState.clock = () => DateTime(2026, 8, 6, 15);

      expect(appState.todayFocusMinutes, 105);
      expect(appState.isDailyTargetMet, isTrue);
      expect(appState.dailyMinutesRemaining, 0);
      // Overshooting the target must not push the bar past 100%.
      expect(appState.dailyProgress, 1.0);
    });

    test('a new day resets daily progress but not lifetime totals', () {
      final SpiralAppState appState = SpiralAppState();
      addTearDown(appState.dispose);

      _logSession(appState, DateTime(2026, 8, 6, 9), minutes: 45);
      appState.clock = () => DateTime(2026, 8, 7, 9);

      expect(appState.todayFocusMinutes, 0);
      expect(appState.totalFocusMinutes, 45);
    });
  });

  group('streaks', () {
    test('consecutive days accumulate', () {
      final SpiralAppState appState = SpiralAppState();
      addTearDown(appState.dispose);

      _logSession(appState, DateTime(2026, 8, 4, 10));
      _logSession(appState, DateTime(2026, 8, 5, 10));
      _logSession(appState, DateTime(2026, 8, 6, 10));

      appState.clock = () => DateTime(2026, 8, 6, 22);
      expect(appState.currentStreakDays, 3);
      expect(appState.longestStreakDays, 3);
    });

    test('multiple sessions in one day count as a single streak day', () {
      final SpiralAppState appState = SpiralAppState();
      addTearDown(appState.dispose);

      _logSession(appState, DateTime(2026, 8, 6, 9));
      _logSession(appState, DateTime(2026, 8, 6, 13));
      _logSession(appState, DateTime(2026, 8, 6, 19));

      appState.clock = () => DateTime(2026, 8, 6, 21);
      expect(appState.currentStreakDays, 1);
    });

    test('an unfocused day today keeps a streak that ran through yesterday', () {
      final SpiralAppState appState = SpiralAppState();
      addTearDown(appState.dispose);

      _logSession(appState, DateTime(2026, 8, 4, 10));
      _logSession(appState, DateTime(2026, 8, 5, 10));

      // Nothing logged on the 6th yet — the streak shouldn't reset at midnight.
      appState.clock = () => DateTime(2026, 8, 6, 8);
      expect(appState.currentStreakDays, 2);
    });

    test('a fully missed day breaks the streak', () {
      final SpiralAppState appState = SpiralAppState();
      addTearDown(appState.dispose);

      _logSession(appState, DateTime(2026, 8, 1, 10));
      _logSession(appState, DateTime(2026, 8, 2, 10));
      // 3rd and 4th skipped.
      _logSession(appState, DateTime(2026, 8, 5, 10));

      appState.clock = () => DateTime(2026, 8, 5, 20);
      expect(appState.currentStreakDays, 1);
      expect(appState.longestStreakDays, 2);
    });

    test('streaks span month boundaries', () {
      final SpiralAppState appState = SpiralAppState();
      addTearDown(appState.dispose);

      _logSession(appState, DateTime(2026, 7, 30, 10));
      _logSession(appState, DateTime(2026, 7, 31, 10));
      _logSession(appState, DateTime(2026, 8, 1, 10));

      appState.clock = () => DateTime(2026, 8, 1, 20);
      expect(appState.currentStreakDays, 3);
    });
  });

  test('recentDailyTotals returns a padded, oldest-first window', () {
    final SpiralAppState appState = SpiralAppState();
    addTearDown(appState.dispose);

    _logSession(appState, DateTime(2026, 8, 6, 10), minutes: 40);
    _logSession(appState, DateTime(2026, 8, 4, 10), minutes: 20);
    // Outside the 7-day window ending on the 6th.
    _logSession(appState, DateTime(2026, 7, 20, 10), minutes: 99);

    appState.clock = () => DateTime(2026, 8, 6, 18);
    final List<DailyFocusTotal> week = appState.recentDailyTotals();

    expect(week.length, 7);
    expect(week.first.date, DateTime(2026, 7, 31));
    expect(week.last.date, DateTime(2026, 8, 6));
    expect(
      week.map((DailyFocusTotal day) => day.minutes).toList(),
      <int>[0, 0, 0, 0, 20, 0, 40],
    );
  });

  test('history survives a save/load round trip through the local cache', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SpiralAppState appState = SpiralAppState();
    addTearDown(appState.dispose);

    await appState.login(email: 'player@example.com', password: 'secret');
    appState.setDailyTarget(60);
    _logSession(appState, DateTime(2026, 8, 5, 10), minutes: 30);
    _logSession(appState, DateTime(2026, 8, 6, 10), minutes: 45);
    // finishFocusSession persists asynchronously; let the write settle.
    await Future<void>.delayed(Duration.zero);

    // A fresh instance hydrates from the same mock preferences store.
    final SpiralAppState restored = SpiralAppState();
    addTearDown(restored.dispose);
    await Future<void>.delayed(Duration.zero);

    expect(restored.loggedSessionCount, 2);
    expect(restored.sessionHistory.first.wholeMinutes, 45);
    expect(restored.sessionHistory.last.wholeMinutes, 30);

    restored.clock = () => DateTime(2026, 8, 6, 18);
    expect(restored.todayFocusMinutes, 45);
    expect(restored.currentStreakDays, 2);
  });

  test('malformed history entries are dropped instead of crashing', () {
    final SpiralAppState appState = SpiralAppState();
    addTearDown(appState.dispose);

    expect(FocusSessionRecord.fromJson(null), isNull);
    expect(FocusSessionRecord.fromJson('nonsense'), isNull);
    expect(
      FocusSessionRecord.fromJson(<String, Object?>{'seconds': 60}),
      isNull, // missing completedAt
    );
    expect(
      FocusSessionRecord.fromJson(<String, Object?>{
        'completedAt': DateTime(2026, 8, 6).millisecondsSinceEpoch,
        'seconds': -5,
      }),
      isNull,
    );

    final FocusSessionRecord? valid = FocusSessionRecord.fromJson(
      <String, Object?>{
        'completedAt': DateTime(2026, 8, 6, 10).millisecondsSinceEpoch,
        'seconds': 1800,
      },
    );
    expect(valid, isNotNull);
    expect(valid!.wholeMinutes, 30);
    // Absent optional fields fall back rather than throwing.
    expect(valid.bitsEarned, 0);
    expect(valid.difficulty, AppDifficulty.highSchool);
  });
}
