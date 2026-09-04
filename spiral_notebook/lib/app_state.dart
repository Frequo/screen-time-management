import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spiral_notebook/models/game_character.dart';
import 'package:spiral_notebook/services/character_catalog.dart';

export 'package:spiral_notebook/models/game_character.dart';

enum AppDifficulty { elementary, middle, highSchool, college }

enum PhoneStandConnectionStatus {
  unsupported,
  disconnected,
  scanning,
  connecting,
  connected,
  error,
}

extension PhoneStandConnectionStatusDetails on PhoneStandConnectionStatus {
  String get label => switch (this) {
    PhoneStandConnectionStatus.unsupported => 'Bluetooth unavailable',
    PhoneStandConnectionStatus.disconnected => 'Stand disconnected',
    PhoneStandConnectionStatus.scanning => 'Scanning for stand',
    PhoneStandConnectionStatus.connecting => 'Connecting to stand',
    PhoneStandConnectionStatus.connected => 'Stand connected',
    PhoneStandConnectionStatus.error => 'Connection issue',
  };
}

enum TutorialStep {
  inventoryWelcome,
  bitsBalance,
  difficultyRewards,
  collection,
  openFocus,
  startFocus,
  focusTargets,
  openGacha,
  gachaBits,
  drawOne,
  openSettings,
  settingsDifficulty,
  settingsReactivate,
  finish,
}

extension AppDifficultyDetails on AppDifficulty {
  String get label => switch (this) {
    AppDifficulty.elementary => 'Elementary',
    AppDifficulty.middle => 'Middle School',
    AppDifficulty.highSchool => 'High School',
    AppDifficulty.college => 'College',
  };

  String get subtitle => switch (this) {
    AppDifficulty.elementary => 'Fastest rewards, best for short sessions',
    AppDifficulty.middle => 'Steady pacing with moderate rewards',
    AppDifficulty.highSchool => 'Balanced pace for daily work blocks',
    AppDifficulty.college => 'Slowest rate, highest commitment',
  };

  int get rewardPerMinute => switch (this) {
    AppDifficulty.elementary => 15,
    AppDifficulty.middle => 10,
    AppDifficulty.highSchool => 5,
    AppDifficulty.college => 3,
  };
}

enum AppAccentStyle { mint, sunflower, sky, rose }

extension AppAccentStyleDetails on AppAccentStyle {
  // TODO: turn selection to a color picker
  String get label => switch (this) {
    AppAccentStyle.mint => 'Mint',
    AppAccentStyle.sunflower => 'Yellow',
    AppAccentStyle.sky => 'Sky',
    AppAccentStyle.rose => 'Rose',
  };

  Color get lightPrimary => switch (this) {
    AppAccentStyle.mint => const Color(0xFF5DAFA3),
    AppAccentStyle.sunflower => const Color(0xFFC99A10),
    AppAccentStyle.sky => const Color(0xFF4A90E2),
    AppAccentStyle.rose => const Color(0xFFD76684),
  };

  Color get darkPrimary => switch (this) {
    AppAccentStyle.mint => const Color(0xFF78C3B8),
    AppAccentStyle.sunflower => const Color(0xFFFFD36A),
    AppAccentStyle.sky => const Color(0xFF7DB9FF),
    AppAccentStyle.rose => const Color(0xFFFF97B0),
  };

  Color get lightSecondary => switch (this) {
    AppAccentStyle.mint => const Color(0xFF7D90C8),
    AppAccentStyle.sunflower => const Color(0xFFE4A11B),
    AppAccentStyle.sky => const Color(0xFF7D90C8),
    AppAccentStyle.rose => const Color(0xFFC97DA0),
  };

  Color get darkSecondary => switch (this) {
    AppAccentStyle.mint => const Color(0xFF9AACE7),
    AppAccentStyle.sunflower => const Color(0xFFFFC14D),
    AppAccentStyle.sky => const Color(0xFFA6C6FF),
    AppAccentStyle.rose => const Color(0xFFFFB3C6),
  };
}

class FocusSessionResult {
  const FocusSessionResult({
    required this.seconds,
    required this.rewardsEarned,
    required this.label,
  });

  final int seconds;
  final int rewardsEarned;
  final String label;

  int get wholeMinutes => seconds ~/ 60;
}

/// One completed focus session, kept in [SpiralAppState.sessionHistory] so the
/// app can show streaks, daily progress, and a per-session log instead of only
/// lifetime totals.
class FocusSessionRecord {
  const FocusSessionRecord({
    required this.completedAt,
    required this.seconds,
    required this.bitsEarned,
    required this.difficulty,
    required this.targetMinutes,
    required this.label,
  });

  final DateTime completedAt;
  final int seconds;
  final int bitsEarned;
  final AppDifficulty difficulty;
  final int targetMinutes;
  final String label;

  int get wholeMinutes => seconds ~/ 60;

  /// True when the session ran at least as long as the target picked for it.
  bool get metTarget => targetMinutes > 0 && wholeMinutes >= targetMinutes;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'completedAt': completedAt.millisecondsSinceEpoch,
      'seconds': seconds,
      'bitsEarned': bitsEarned,
      'difficulty': difficulty.name,
      'targetMinutes': targetMinutes,
      'label': label,
    };
  }

  /// Returns null for entries that are missing or malformed, so one bad row in
  /// a cached/synced payload can't take down the whole history.
  static FocusSessionRecord? fromJson(Object? value) {
    if (value is! Map) {
      return null;
    }

    final int? millis = (value['completedAt'] as num?)?.toInt();
    final int? seconds = (value['seconds'] as num?)?.toInt();
    if (millis == null || seconds == null || seconds < 0) {
      return null;
    }

    return FocusSessionRecord(
      completedAt: DateTime.fromMillisecondsSinceEpoch(millis),
      seconds: seconds,
      bitsEarned: (value['bitsEarned'] as num?)?.toInt() ?? 0,
      difficulty: AppDifficulty.values.firstWhere(
        (AppDifficulty difficulty) => difficulty.name == value['difficulty'],
        orElse: () => AppDifficulty.highSchool,
      ),
      targetMinutes: (value['targetMinutes'] as num?)?.toInt() ?? 0,
      label: value['label'] as String? ?? '',
    );
  }
}

/// Focus minutes for a single calendar day, used by the history chart.
class DailyFocusTotal {
  const DailyFocusTotal({required this.date, required this.minutes});

  final DateTime date;
  final int minutes;
}

class SpiralAppState extends ChangeNotifier {
  SpiralAppState({
    required List<GameCharacter> roster,
    this.firebaseEnabled = false,
    Stream<List<GameCharacter>>? characterUpdates,
  }) : _characterCatalog = List<GameCharacter>.unmodifiable(roster) {
    final Stream<List<GameCharacter>>? updates =
        characterUpdates ??
        (firebaseEnabled ? watchCharacterRoster() : null);
    _characterSubscription = updates?.listen(
      updateCharacterRoster,
      onError: (Object error) {
        debugPrint('Keeping last usable character catalog: $error');
      },
    );
    // Keep a handle to the local-cache load so the Firebase reconcile can wait
    // for it (otherwise the cached updatedAtClient/progress may not be in memory
    // yet and a stale server snapshot could clobber newer offline progress).
    _localHydration = _hydrateLocalCache();
    unawaited(_localHydration!);

    if (!firebaseEnabled) {
      return;
    }

    _syncFromFirebaseUser(FirebaseAuth.instance.currentUser, notify: false);
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((
      User? user,
    ) {
      unawaited(_handleAuthStateChanged(user));
    });
  }

  static const int pullCost = 100;
  static const int pityLimit = 100;
  static const List<int> focusTargets = <int>[10, 25, 45, 60];

  /// Newest-first cap on [sessionHistory]. Keeps the Firestore document and the
  /// SharedPreferences payload small; lifetime aggregates (totalFocusMinutes,
  /// bestSessionSeconds) are stored separately and are not derived from this.
  static const int sessionHistoryLimit = 120;

  static const String _sessionEmailKey = 'session.email';
  static const String _sessionNameKey = 'session.name';
  static const String _sessionUserIdKey = 'session.userId';
  static const String _progressCacheKey = 'progress.cache';
  static const String _sessionEnabledKey = 'session.enabled';

  final Random _random = Random();
  List<GameCharacter> _characterCatalog;
  StreamSubscription<List<GameCharacter>>? _characterSubscription;

  List<GameCharacter> get roster => List<GameCharacter>.unmodifiable(
    _characterCatalog.where((character) => !character.hidden),
  );

  void updateCharacterRoster(List<GameCharacter> characters) {
    _characterCatalog = List<GameCharacter>.unmodifiable(characters);
    notifyListeners();
  }

  List<GameCharacter> get gachaPool => List<GameCharacter>.unmodifiable(
    roster.where((GameCharacter character) => character.pullable),
  );

  static const Map<CharacterRarity, int> _rarityWeights =
      <CharacterRarity, int>{
        CharacterRarity.common: 680,
        CharacterRarity.rare: 220,
        CharacterRarity.epic: 90,
        CharacterRarity.legendary: 10,
      };

  Map<CharacterRarity, int> get _availableRarityWeights =>
      Map<CharacterRarity, int>.unmodifiable(<CharacterRarity, int>{
        for (final CharacterRarity rarity in CharacterRarity.values)
          if (gachaPool.any(
            (GameCharacter character) => character.rarity == rarity,
          ))
            rarity: _rarityWeights[rarity]!,
      });

  bool get hasPullableLegendary =>
      _availableRarityWeights.containsKey(CharacterRarity.legendary);

  Map<CharacterRarity, double> get gachaRates {
    final int total = _availableRarityWeights.values.fold(
      0,
      (int a, int b) => a + b,
    );
    return <CharacterRarity, double>{
      for (final CharacterRarity rarity in CharacterRarity.values)
        rarity: total == 0 ? 0 : (_availableRarityWeights[rarity] ?? 0) / total,
    };
  }

  final Map<String, int> _collection = <String, int>{};
  final List<FocusSessionRecord> _sessionHistory = <FocusSessionRecord>[];
  final bool firebaseEnabled;

  /// Injection point for the "now" used to stamp sessions and to bucket them
  /// into calendar days, so streak and daily-total logic is testable.
  @visibleForTesting
  DateTime Function() clock = DateTime.now;

  StreamSubscription<User?>? _authSubscription;
  Timer? _focusTicker;
  Future<void>? _progressLoad;
  Future<void>? _localHydration;
  int _progressUpdatedAt = 0;
  int? _lockedRewardPerMinute;

  bool isLoggedIn = false;
  String playerName = '';
  String playerEmail = '';
  String? playerId;
  AppDifficulty difficulty = AppDifficulty.highSchool;
  bool soundEnabled = true;
  bool ambientSoundsEnabled = true;
  bool hapticsEnabled = true;
  bool reminderEnabled = true;
  bool sessionBackgroundEnabled = true;

  // Compatibility alias for older references.
  // ignore: non_constant_identifier_names
  bool get SessionBackEnabled => sessionBackgroundEnabled;

  // ignore: non_constant_identifier_names
  set SessionBackEnabled(bool value) => setSessionBackgroundEnabled(value);

  ThemeMode themeMode = ThemeMode.light;
  AppAccentStyle accentStyle = AppAccentStyle.mint;
  int dailyTargetMinutes = 90;
  int selectedFocusTarget = 25;
  bool isFocusActive = false;
  bool isFocusPaused = false;
  int currentSessionSeconds = 0;
  int totalFocusMinutes = 0;
  int bestSessionSeconds = 0;
  int bits = 0;
  int totalPulls = 0;
  int pityCounter = 0;
  bool hasCompletedTutorial = false;
  bool isTutorialActive = false;
  TutorialStep tutorialStep = TutorialStep.inventoryWelcome;
  PhoneStandConnectionStatus phoneStandConnectionStatus =
      PhoneStandConnectionStatus.disconnected;
  bool isPhoneOnStand = false;
  bool _pausedByPhoneStand = false;
  int? phoneStandSensorValue;
  int? phoneStandOnThreshold;
  int? phoneStandOffThreshold;
  String phoneStandMessage =
      'Connect the stand before starting a hardware focus session.';
  FocusSessionResult? lastFocusResult;
  String? _lastPulledCharacterId;
  GameCharacter? get lastPulledCharacter =>
      visibleCharacterById(_lastPulledCharacterId ?? '');
  set lastPulledCharacter(GameCharacter? character) =>
      _lastPulledCharacterId = character?.id;
  List<GameCharacter> _lastPulledCharacters = <GameCharacter>[];
  List<GameCharacter> get lastPulledCharacters => List<GameCharacter>.unmodifiable(
    _lastPulledCharacters
        .map((character) => visibleCharacterById(character.id))
        .whereType<GameCharacter>(),
  );
  set lastPulledCharacters(List<GameCharacter> characters) =>
      _lastPulledCharacters = List<GameCharacter>.unmodifiable(characters);

  Map<String, int> get collection => Map<String, int>.unmodifiable(_collection);

  int get collectedCount => roster
      .where((GameCharacter character) => copiesOwned(character) > 0)
      .length;

  int get duplicateCount =>
      _collection.values.fold<int>(0, (int total, int copies) {
        if (copies <= 1) {
          return total;
        }
        return total + copies - 1;
      });

  int get pityRemaining => max(0, pityLimit - pityCounter);

  double get pityProgress =>
      pityLimit == 0 ? 0 : (pityCounter / pityLimit).clamp(0, 1).toDouble();

  double get collectionProgress =>
      roster.isEmpty ? 0 : collectedCount / roster.length;

  int get currentRewardPreview =>
      calculateRewardForSeconds(selectedFocusTarget * 60);

  int get remainingTargetSeconds =>
      max(0, selectedFocusTarget * 60 - currentSessionSeconds);

  /// Completed sessions, newest first.
  List<FocusSessionRecord> get sessionHistory =>
      List<FocusSessionRecord>.unmodifiable(_sessionHistory);

  int get loggedSessionCount => _sessionHistory.length;

  /// Midnight of the current calendar day. The UI reads "today" from here so
  /// the widgets and the stats below can never disagree about the date.
  DateTime get todayDate => _dayKey(clock());

  /// Focus minutes recorded so far on the current calendar day.
  int get todayFocusMinutes {
    final DateTime today = todayDate;
    return _sessionHistory
        .where(
          (FocusSessionRecord record) => _dayKey(record.completedAt) == today,
        )
        .fold<int>(
          0,
          (int total, FocusSessionRecord record) => total + record.wholeMinutes,
        );
  }

  int get dailyProgressMinutes => min(todayFocusMinutes, dailyTargetMinutes);

  double get dailyProgress => dailyTargetMinutes == 0
      ? 0
      : (todayFocusMinutes / dailyTargetMinutes).clamp(0, 1).toDouble();

  bool get isDailyTargetMet => todayFocusMinutes >= dailyTargetMinutes;

  int get dailyMinutesRemaining => max(0, dailyTargetMinutes - todayFocusMinutes);

  /// Consecutive calendar days ending today (or yesterday, if today has no
  /// session yet) on which at least one session was recorded.
  int get currentStreakDays {
    final Set<DateTime> days = _focusDays();
    if (days.isEmpty) {
      return 0;
    }

    final DateTime today = todayDate;
    DateTime cursor = today;
    if (!days.contains(cursor)) {
      // Today isn't logged yet — an unbroken run through yesterday still
      // counts, so the streak doesn't visibly reset every morning.
      cursor = _previousDay(today);
      if (!days.contains(cursor)) {
        return 0;
      }
    }

    int streak = 0;
    while (days.contains(cursor)) {
      streak += 1;
      cursor = _previousDay(cursor);
    }
    return streak;
  }

  int get longestStreakDays {
    final List<DateTime> days = _focusDays().toList(growable: false)..sort();
    if (days.isEmpty) {
      return 0;
    }

    int longest = 1;
    int running = 1;
    for (int i = 1; i < days.length; i += 1) {
      if (days[i] == _nextDay(days[i - 1])) {
        running += 1;
        longest = max(longest, running);
      } else {
        running = 1;
      }
    }
    return longest;
  }

  /// Focus minutes per day for the [days]-day window ending today, oldest
  /// first. Days with no sessions are included with zero minutes so the chart
  /// keeps a stable width.
  List<DailyFocusTotal> recentDailyTotals({int days = 7}) {
    final Map<DateTime, int> minutesByDay = <DateTime, int>{};
    for (final FocusSessionRecord record in _sessionHistory) {
      final DateTime day = _dayKey(record.completedAt);
      minutesByDay[day] = (minutesByDay[day] ?? 0) + record.wholeMinutes;
    }

    final DateTime today = todayDate;
    return List<DailyFocusTotal>.generate(days, (int index) {
      final DateTime day = DateTime(
        today.year,
        today.month,
        today.day - (days - 1 - index),
      );
      return DailyFocusTotal(date: day, minutes: minutesByDay[day] ?? 0);
    }, growable: false);
  }

  Set<DateTime> _focusDays() {
    return _sessionHistory
        .map((FocusSessionRecord record) => _dayKey(record.completedAt))
        .toSet();
  }

  // Day arithmetic goes through the DateTime constructor rather than
  // Duration(days: 1): adding a fixed 24 hours across a DST boundary lands on
  // 23:00 or 01:00 of the neighbouring day, which would never compare equal to
  // a midnight day key.
  static DateTime _dayKey(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static DateTime _previousDay(DateTime day) =>
      DateTime(day.year, day.month, day.day - 1);

  static DateTime _nextDay(DateTime day) =>
      DateTime(day.year, day.month, day.day + 1);

  bool get isPhoneStandConnected =>
      phoneStandConnectionStatus == PhoneStandConnectionStatus.connected;

  bool get isFocusPausedByPhoneStand => _pausedByPhoneStand;

  bool get canStartFocusSession =>
      !isPhoneStandConnected || isPhoneOnStand || isFocusPaused;

  Future<void> login({
    required String email,
    required String password,
    String displayName = '',
    bool createAccount = false,
  }) async {
    final String trimmedEmail = email.trim();
    final String normalizedName = _normalizedName(
      displayName: displayName,
      email: trimmedEmail,
    );

    if (!firebaseEnabled) {
      _applyLocalLogin(normalizedName, trimmedEmail);
      await _persistLocalCache();
      _maybeStartOnboarding(createAccount);
      return;
    }

    try {
      final UserCredential credential = createAccount
          ? await FirebaseAuth.instance.createUserWithEmailAndPassword(
              email: trimmedEmail,
              password: password,
            )
          : await FirebaseAuth.instance.signInWithEmailAndPassword(
              email: trimmedEmail,
              password: password,
            );

      User user = credential.user!;
      final String resolvedName = _normalizedName(
        displayName: user.displayName ?? normalizedName,
        email: trimmedEmail,
      );

      if (user.displayName != resolvedName) {
        await user.updateDisplayName(resolvedName);
      }
      await user.reload();
      user = FirebaseAuth.instance.currentUser ?? user;

      _syncFromFirebaseUser(user, fallbackEmail: trimmedEmail);
      await _persistLocalCache();
      await _syncProfileToFirebase(
        user: user,
        resolvedName: resolvedName,
        email: trimmedEmail,
      );
      await _loadProgressFromFirebase();
      _maybeStartOnboarding(createAccount);
      return;
    } on FirebaseAuthException catch (error) {
      if (await _canRecoverFromNetworkSignInFailure(
        error,
        email: trimmedEmail,
      )) {
        _applyLocalLogin(
          await _cachedNameForEmail(trimmedEmail) ?? normalizedName,
          trimmedEmail,
        );
        await _persistLocalCache();
        await _hydrateProgressFromLocalCache();
        return;
      }
      rethrow;
    }
  }

  // Starts the first-time tutorial for a freshly created account. This lives in
  // the app state (not the login screen) because the reactive auth gate unmounts
  // the login screen as soon as isLoggedIn flips true, so post-await code there
  // is not guaranteed to run.
  void _maybeStartOnboarding(bool createAccount) {
    if (createAccount && !hasCompletedTutorial) {
      startTutorial();
    }
  }

  Future<void> logout() async {
    _stopTicker();
    isFocusActive = false;
    isFocusPaused = false;
    currentSessionSeconds = 0;

    if (firebaseEnabled && FirebaseAuth.instance.currentUser != null) {
      await _clearLocalCache();
      await FirebaseAuth.instance.signOut();
      return;
    }

    await _clearLocalCache();
    _clearSession();
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    _stopTicker();
    isFocusActive = false;
    isFocusPaused = false;
    currentSessionSeconds = 0;

    if (firebaseEnabled) {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Delete the Firestore profile FIRST, while the user is still
        // authenticated. Security rules typically only let a user delete their
        // own document, so doing this after user.delete() would be rejected and
        // leave the profile (and its PII) orphaned in Firestore.
        bool deletedProfile = false;
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .delete();
          deletedProfile = true;
        } on FirebaseException {
          // Best effort; proceed with auth deletion regardless.
        }

        try {
          await user.delete();
        } catch (error) {
          // Auth deletion commonly fails with requires-recent-login. Restore the
          // profile + progress we just removed so the account isn't left
          // half-deleted (cloud progress wiped while the login still works),
          // then rethrow so the UI can prompt a re-login and retry.
          if (deletedProfile) {
            await _syncProfileToFirebase(
              user: user,
              resolvedName: playerName,
              email: playerEmail,
            );
            await _persistProgress();
          }
          rethrow;
        }

        await _clearLocalCache();
        _clearSession();
        notifyListeners();
        return;
      }
    }

    await _clearLocalCache();
    _clearSession();
    notifyListeners();
  }

  void setDifficulty(AppDifficulty value) {
    difficulty = value;
    notifyListeners();
    _persistProgress();
  }

  void setFocusTarget(int value) {
    selectedFocusTarget = value;
    notifyListeners();
    _persistProgress();
  }

  void setDailyTarget(int value) {
    dailyTargetMinutes = value;
    notifyListeners();
    _persistProgress();
  }

  void setSoundEnabled(bool value) {
    soundEnabled = value;
    notifyListeners();
    _persistProgress();
  }

  void setAmbientSoundsEnabled(bool value) {
    ambientSoundsEnabled = value;
    notifyListeners();
    _persistProgress();
  }

  void setHapticsEnabled(bool value) {
    hapticsEnabled = value;
    notifyListeners();
    _persistProgress();
  }

  void setReminderEnabled(bool value) {
    reminderEnabled = value;
    notifyListeners();
    _persistProgress();
  }

  void setSessionBackgroundEnabled(bool value) {
    sessionBackgroundEnabled = value;
    notifyListeners();
    _persistProgress();
  }

  void setThemeMode(ThemeMode value) {
    themeMode = value;
    notifyListeners();
    _persistProgress();
  }

  void setAccentStyle(AppAccentStyle value) {
    accentStyle = value;
    notifyListeners();
    _persistProgress();
  }

  void startTutorial() {
    isTutorialActive = true;
    tutorialStep = TutorialStep.inventoryWelcome;
    notifyListeners();
  }

  void restartTutorialForDebug() {
    hasCompletedTutorial = false;
    startTutorial();
    _persistProgress();
  }

  void advanceTutorial() {
    if (!isTutorialActive) {
      return;
    }

    if (tutorialStep == TutorialStep.finish) {
      completeTutorial();
      return;
    }

    tutorialStep = TutorialStep.values[tutorialStep.index + 1];
    notifyListeners();
  }

  void setTutorialStep(TutorialStep step) {
    if (!isTutorialActive || tutorialStep == step) {
      return;
    }

    tutorialStep = step;
    notifyListeners();
  }

  void skipTutorial() {
    if (!isTutorialActive && hasCompletedTutorial) {
      return;
    }

    isTutorialActive = false;
    hasCompletedTutorial = true;
    tutorialStep = TutorialStep.inventoryWelcome;
    notifyListeners();
    _persistProgress();
  }

  void completeTutorial() {
    if (!isTutorialActive && hasCompletedTutorial) {
      return;
    }

    bits += 100;
    isTutorialActive = false;
    hasCompletedTutorial = true;
    tutorialStep = TutorialStep.inventoryWelcome;
    notifyListeners();
    _persistProgress();
  }

  void startFocusSession() {
    if (isFocusActive && !isFocusPaused) {
      return;
    }

    if (!canStartFocusSession) {
      phoneStandMessage = 'Put the phone on the stand to start the session.';
      notifyListeners();
      return;
    }

    if (!isFocusPaused) {
      currentSessionSeconds = 0;
      // Lock the reward rate to the difficulty chosen when the session begins,
      // so switching difficulty mid-session can't inflate the payout.
      _lockedRewardPerMinute = difficulty.rewardPerMinute;
    }
    isFocusActive = true;
    isFocusPaused = false;
    _pausedByPhoneStand = false;
    notifyListeners();

    _focusTicker = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      currentSessionSeconds += 1;
      notifyListeners();
    });
  }

  FocusSessionResult? finishFocusSession() {
    if (!isFocusActive && !isFocusPaused) {
      return null;
    }

    _stopTicker();
    isFocusActive = false;
    isFocusPaused = false;
    _pausedByPhoneStand = false;

    final int rewards = calculateRewardForSeconds(currentSessionSeconds);
    final FocusSessionResult result = FocusSessionResult(
      seconds: currentSessionSeconds,
      rewardsEarned: rewards,
      label: _sessionLabel(currentSessionSeconds),
    );

    bits += rewards;
    totalFocusMinutes += currentSessionSeconds ~/ 60;
    bestSessionSeconds = max(bestSessionSeconds, currentSessionSeconds);
    lastFocusResult = result;

    // Sessions shorter than a minute earn nothing and would otherwise pad the
    // log (and light up a streak day) without representing real focus time.
    if (result.wholeMinutes > 0) {
      _sessionHistory.insert(
        0,
        FocusSessionRecord(
          completedAt: clock(),
          seconds: result.seconds,
          bitsEarned: rewards,
          difficulty: difficulty,
          targetMinutes: selectedFocusTarget,
          label: result.label,
        ),
      );
      if (_sessionHistory.length > sessionHistoryLimit) {
        _sessionHistory.removeRange(sessionHistoryLimit, _sessionHistory.length);
      }
    }

    currentSessionSeconds = 0;
    _lockedRewardPerMinute = null;
    notifyListeners();
    _persistProgress();
    return result;
  }

  void cancelFocusSession() {
    _stopTicker();
    isFocusActive = false;
    isFocusPaused = false;
    currentSessionSeconds = 0;
    _lockedRewardPerMinute = null;
    _pausedByPhoneStand = false;
    notifyListeners();
  }

  void pauseFocusSession({bool byPhoneStand = false}) {
    if (!isFocusActive) {
      return;
    }

    _stopTicker();
    isFocusActive = true;
    isFocusPaused = true;
    _pausedByPhoneStand = byPhoneStand;
    notifyListeners();
  }

  void updatePhoneStandConnectionStatus(
    PhoneStandConnectionStatus status, {
    String? message,
  }) {
    final bool wasConnected = isPhoneStandConnected;

    phoneStandConnectionStatus = status;
    if (message != null) {
      phoneStandMessage = message;
    }

    if (status != PhoneStandConnectionStatus.connected) {
      isPhoneOnStand = false;
      phoneStandSensorValue = null;
      if (wasConnected && isFocusActive && !isFocusPaused) {
        pauseFocusSession(byPhoneStand: true);
        return;
      }
    }

    notifyListeners();
  }

  void applyPhoneStandMessage(String rawLine) {
    final String line = rawLine.trim();
    if (line.isEmpty) {
      return;
    }

    final Map<String, String> fields = _parseStandFields(line);
    bool? phonePresent;

    if (line.startsWith('PHONE_ON')) {
      phonePresent = true;
    } else if (line.startsWith('PHONE_OFF')) {
      phonePresent = false;
    } else if (line.startsWith('STATE')) {
      final String? value = fields['phone_present'];
      if (value != null) {
        phonePresent = value == '1' || value.toLowerCase() == 'true';
      }
    }

    if (phonePresent != null) {
      isPhoneOnStand = phonePresent;
    }

    phoneStandSensorValue =
        int.tryParse(fields['value'] ?? '') ?? phoneStandSensorValue;
    phoneStandOnThreshold =
        int.tryParse(fields['on_threshold'] ?? '') ?? phoneStandOnThreshold;
    phoneStandOffThreshold =
        int.tryParse(fields['off_threshold'] ?? '') ?? phoneStandOffThreshold;
    phoneStandMessage = line;

    if (isPhoneStandConnected && phonePresent != null) {
      if (!phonePresent && isFocusActive && !isFocusPaused) {
        pauseFocusSession(byPhoneStand: true);
        return;
      }

      if (phonePresent && isFocusPaused && _pausedByPhoneStand) {
        startFocusSession();
        return;
      }
    }

    notifyListeners();
  }

  int copiesOwned(GameCharacter character) => _collection[character.id] ?? 0;

  bool isCollected(GameCharacter character) => copiesOwned(character) > 0;

  List<GameCharacter> ownedCharacters() {
    return roster
        .where((GameCharacter character) => isCollected(character))
        .toList(growable: false);
  }

  List<GameCharacter> charactersByRarity(CharacterRarity rarity) {
    return roster
        .where((GameCharacter character) => character.rarity == rarity)
        .toList(growable: false);
  }

  GameCharacter? findCharacterById(String id) {
    for (final GameCharacter character in _characterCatalog) {
      if (character.id == id) {
        return character;
      }
    }
    return null;
  }

  GameCharacter? visibleCharacterById(String id) {
    final GameCharacter? character = findCharacterById(id);
    return character == null || character.hidden ? null : character;
  }

  GameCharacter? pullCharacter() {
    final List<GameCharacter>? results = pullCharacters(1);
    if (results == null || results.isEmpty) {
      return null;
    }
    return results.first;
  }

  List<GameCharacter>? pullCharacters(int count) {
    if (count <= 0 || bits < pullCost * count || gachaPool.isEmpty) {
      return null;
    }

    final List<GameCharacter> results = <GameCharacter>[];
    for (int index = 0; index < count; index += 1) {
      results.add(_performPull());
    }

    // _performPull() already resets pityCounter to 0 on every legendary (natural
    // or pity-guaranteed), so no batch-level reset is needed. A redundant reset
    // here would wipe pity legitimately earned by pulls after a mid-batch
    // legendary.
    lastPulledCharacter = results.last;
    lastPulledCharacters = List<GameCharacter>.unmodifiable(results);
    notifyListeners();
    _persistProgress();
    return results;
  }

  List<GameCharacter> tutorialDrawOne() {
    if (gachaPool.isEmpty) {
      return const <GameCharacter>[];
    }
    if (bits < pullCost) {
      bits += pullCost - bits;
    }

    final GameCharacter pulled = _performPull();
    lastPulledCharacter = pulled;
    lastPulledCharacters = List<GameCharacter>.unmodifiable(<GameCharacter>[
      pulled,
    ]);
    notifyListeners();
    _persistProgress();
    return lastPulledCharacters;
  }

  GameCharacter _performPull() {
    bits -= pullCost;
    totalPulls += 1;
    pityCounter += 1;

    final bool guaranteedLegendary =
        pityCounter >= pityLimit && hasPullableLegendary;
    final CharacterRarity rarity = _rollRarity(
      guaranteedLegendary: guaranteedLegendary,
    );
    final List<GameCharacter> rarityPool = gachaPool
        .where((GameCharacter character) => character.rarity == rarity)
        .toList(growable: false);
    final List<GameCharacter> missingFromPool = rarityPool
        .where((GameCharacter character) => !isCollected(character))
        .toList(growable: false);

    final List<GameCharacter> pool =
        missingFromPool.isNotEmpty && _random.nextDouble() < 0.7
        ? missingFromPool
        : rarityPool;
    final GameCharacter pulled = pool[_random.nextInt(pool.length)];

    _collection.update(pulled.id, (int value) => value + 1, ifAbsent: () => 1);

    if (pulled.rarity == CharacterRarity.legendary || guaranteedLegendary) {
      pityCounter = 0;
    }

    return pulled;
  }

  int calculateRewardForSeconds(int seconds) {
    final int wholeMinutes = seconds ~/ 60;
    if (wholeMinutes == 0) {
      return 0;
    }

    // While a session is in progress the lock is set (at session start) and is
    // cleared when the session ends, so the payout — computed in
    // finishFocusSession after isFocusActive is already false — still uses the
    // rate from session start. Outside a session the lock is null and the live
    // difficulty drives the reward preview.
    final int rewardPerMinute =
        _lockedRewardPerMinute ?? difficulty.rewardPerMinute;

    int reward = wholeMinutes * rewardPerMinute;
    if (wholeMinutes >= 20) {
      reward += 15;
    }
    if (wholeMinutes >= 45) {
      reward += 25;
    }
    return reward;
  }

  String formatDuration(int totalSeconds) {
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    final String paddedMinutes = minutes.toString().padLeft(2, '0');
    final String paddedSeconds = seconds.toString().padLeft(2, '0');
    return '$paddedMinutes:$paddedSeconds';
  }

  String minutesLabel(int totalMinutes) {
    return totalMinutes == 1 ? '1 minute' : '$totalMinutes minutes';
  }

  @override
  void dispose() {
    _stopTicker();
    _authSubscription?.cancel();
    _characterSubscription?.cancel();
    super.dispose();
  }

  void _stopTicker() {
    _focusTicker?.cancel();
    _focusTicker = null;
  }

  Map<String, String> _parseStandFields(String line) {
    final Map<String, String> fields = <String, String>{};
    for (final String part in line.split(',')) {
      final int separator = part.indexOf('=');
      if (separator <= 0 || separator == part.length - 1) {
        continue;
      }
      fields[part.substring(0, separator).trim()] = part
          .substring(separator + 1)
          .trim();
    }
    return fields;
  }

  void _applyLocalLogin(String name, String email) {
    playerName = name;
    playerEmail = email;
    playerId = null;
    isLoggedIn = true;
    notifyListeners();
  }

  void _clearSession() {
    _resetProgress();
    playerName = '';
    playerEmail = '';
    playerId = null;
    isLoggedIn = false;
  }

  String _normalizedName({required String displayName, required String email}) {
    final String trimmedName = displayName.trim();
    if (trimmedName.isNotEmpty) {
      return trimmedName;
    }

    if (email.contains('@')) {
      return email.split('@').first;
    }

    return 'username';
  }

  void _syncFromFirebaseUser(
    User? user, {
    String? fallbackEmail,
    bool notify = true,
  }) {
    if (user == null) {
      _clearSession();
      if (notify) {
        notifyListeners();
      }
      return;
    }

    final String resolvedEmail = user.email ?? fallbackEmail ?? playerEmail;
    playerName = _normalizedName(
      displayName: user.displayName ?? '',
      email: resolvedEmail,
    );
    playerEmail = resolvedEmail;
    playerId = user.uid;
    isLoggedIn = true;

    if (notify) {
      notifyListeners();
    }
  }

  Future<void> _handleAuthStateChanged(User? user) async {
    _syncFromFirebaseUser(user);
    if (user == null) {
      return;
    }
    // Restore progress from the still-intact local cache before persisting or
    // reconciling. A prior transient null auth emission clears in-memory
    // progress via _clearSession but leaves the prefs cache untouched; without
    // re-reading it here, the _persistLocalCache below would overwrite the good
    // cache with defaults and the server reconcile would then clobber newer
    // offline progress. Only re-read when the cache belongs to THIS user: a
    // session can also end without clearing the cache (token expiry), so a
    // different account signing in next must not inherit the prior user's
    // cached progress.
    try {
      await _localHydration;
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_sessionUserIdKey) == user.uid) {
        await _hydrateProgressFromLocalCache(preferences: prefs);
      }
    } catch (_) {
      // Ignore cache-load failures; fall back to server data.
    }
    await _persistLocalCache();
    await _loadProgressFromFirebase();
  }

  Future<void> _loadProgressFromFirebase() {
    final String? uid = playerId;
    if (!firebaseEnabled || uid == null) {
      return Future<void>.value();
    }

    // Coalesce concurrent loads. On sign-in both login() and the
    // authStateChanges listener kick off a load; sharing one in-flight fetch
    // avoids duplicate reads and a non-deterministic last-writer.
    return _progressLoad ??= _loadProgressFromFirebaseImpl(uid).whenComplete(() {
      _progressLoad = null;
    });
  }

  Future<void> _loadProgressFromFirebaseImpl(String uid) async {
    // Ensure the local cache (identity + progress + updatedAtClient) is in
    // memory before reconciling against the server, so newer offline progress
    // is detected by timestamp instead of being clobbered — even on a cold
    // start where the session was restored from Firebase auth and the cache
    // load would otherwise race this fetch.
    try {
      await _localHydration;
    } catch (_) {
      // Ignore cache-load failures; fall back to server data.
    }
    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final Map<String, dynamic>? data = snapshot.data();
      if (data == null) {
        // No server document yet — seed it from current (local) progress.
        await _persistProgress();
        return;
      }

      // Last-write-wins by client timestamp. If local progress is newer than
      // this snapshot (earned offline, or mutated while the fetch was in
      // flight), push local up instead of clobbering it.
      final int serverUpdatedAt =
          (data['updatedAtClient'] as num?)?.toInt() ?? 0;
      if (serverUpdatedAt < _progressUpdatedAt) {
        await _persistProgress();
        return;
      }
      _progressUpdatedAt = serverUpdatedAt;

      final Map<String, dynamic> collectionData =
          (data['collection'] as Map<String, dynamic>?) ?? <String, dynamic>{};
      _collection
        ..clear()
        ..addEntries(
          collectionData.entries.map(
            (MapEntry<String, dynamic> entry) => MapEntry<String, int>(
              entry.key,
              (entry.value as num?)?.toInt() ?? 0,
            ),
          ),
        );
      difficulty = _difficultyFromName(data['difficulty'] as String?);
      soundEnabled = data['soundEnabled'] as bool? ?? soundEnabled;
      ambientSoundsEnabled =
          data['ambientSoundsEnabled'] as bool? ?? ambientSoundsEnabled;
      hapticsEnabled = data['hapticsEnabled'] as bool? ?? hapticsEnabled;
      reminderEnabled = data['reminderEnabled'] as bool? ?? reminderEnabled;
      sessionBackgroundEnabled =
          data['sessionBackgroundEnabled'] as bool? ?? sessionBackgroundEnabled;
      dailyTargetMinutes =
          (data['dailyTargetMinutes'] as num?)?.toInt() ?? dailyTargetMinutes;
      selectedFocusTarget =
          (data['selectedFocusTarget'] as num?)?.toInt() ?? selectedFocusTarget;
      totalFocusMinutes =
          (data['totalFocusMinutes'] as num?)?.toInt() ?? totalFocusMinutes;
      bestSessionSeconds =
          (data['bestSessionSeconds'] as num?)?.toInt() ?? bestSessionSeconds;
      bits = (data['bits'] as num?)?.toInt() ?? bits;
      totalPulls = (data['totalPulls'] as num?)?.toInt() ?? totalPulls;
      pityCounter = (data['pityCounter'] as num?)?.toInt() ?? pityCounter;
      hasCompletedTutorial =
          data['hasCompletedTutorial'] as bool? ?? hasCompletedTutorial;
      themeMode = _themeModeFromName(data['themeMode'] as String?);
      accentStyle = _accentStyleFromName(
        data['accentStyle'] as String? ?? data['backgroundStyle'] as String?,
      );
      _lastPulledCharacterId = data['lastPulledCharacterId'] as String?;
      _applySessionHistoryData(data['sessionHistory']);
      await _persistLocalCache();
      notifyListeners();
    } on FirebaseException {
      await _hydrateProgressFromLocalCache();
    }
  }

  Future<void> _persistProgress() async {
    // Stamp this save so loads can reconcile local vs server by recency.
    _progressUpdatedAt = DateTime.now().millisecondsSinceEpoch;
    try {
      await _persistLocalCache();
    } catch (_) {
      // Local cache is best-effort; ignore storage failures.
    }
    if (!firebaseEnabled || playerId == null) {
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('users').doc(playerId).set(<
        String,
        Object?
      >{
        'collection': _collection,
        'difficulty': difficulty.name,
        'soundEnabled': soundEnabled,
        'ambientSoundsEnabled': ambientSoundsEnabled,
        'hapticsEnabled': hapticsEnabled,
        'reminderEnabled': reminderEnabled,
        'sessionBackgroundEnabled': sessionBackgroundEnabled,
        'dailyTargetMinutes': dailyTargetMinutes,
        'selectedFocusTarget': selectedFocusTarget,
        'totalFocusMinutes': totalFocusMinutes,
        'bestSessionSeconds': bestSessionSeconds,
        'bits': bits,
        'totalPulls': totalPulls,
        'pityCounter': pityCounter,
        'hasCompletedTutorial': hasCompletedTutorial,
        'themeMode': themeMode.name,
        'accentStyle': accentStyle.name,
        'lastPulledCharacterId': _lastPulledCharacterId,
        'sessionHistory': _sessionHistoryData(),
        'updatedAtClient': _progressUpdatedAt,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException {
      // Offline or transient failure. The local cache holds the latest state
      // and the next successful load reconciles via updatedAtClient.
    }
  }

  Future<void> _hydrateLocalCache() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool hasSession = prefs.getBool(_sessionEnabledKey) ?? false;
    if (!hasSession) {
      return;
    }

    if (!isLoggedIn) {
      // Restore the session identity from cache (offline, or before Firebase
      // has restored the auth user).
      playerName = prefs.getString(_sessionNameKey) ?? '';
      playerEmail = prefs.getString(_sessionEmailKey) ?? '';
      playerId = prefs.getString(_sessionUserIdKey);
      isLoggedIn = playerEmail.isNotEmpty;
    }

    // Always hydrate cached progress (and its updatedAtClient) into memory —
    // even when Firebase already restored the session on cold start — so the
    // later server reconcile can detect newer offline progress by timestamp
    // instead of clobbering it.
    await _hydrateProgressFromLocalCache(preferences: prefs);
    notifyListeners();
  }

  Future<void> _hydrateProgressFromLocalCache({
    SharedPreferences? preferences,
  }) async {
    final SharedPreferences prefs =
        preferences ?? await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_progressCacheKey);
    if (raw == null || raw.isEmpty) {
      return;
    }

    final Map<String, dynamic> data;
    try {
      data = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      // Corrupted or legacy cache payload — discard it and keep defaults
      // instead of crashing on launch.
      await prefs.remove(_progressCacheKey);
      return;
    }

    _progressUpdatedAt =
        (data['updatedAtClient'] as num?)?.toInt() ?? _progressUpdatedAt;
    final Map<String, dynamic> collectionData =
        (data['collection'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    _collection
      ..clear()
      ..addEntries(
        collectionData.entries.map(
          (MapEntry<String, dynamic> entry) => MapEntry<String, int>(
            entry.key,
            (entry.value as num?)?.toInt() ?? 0,
          ),
        ),
      );
    difficulty = _difficultyFromName(data['difficulty'] as String?);
    soundEnabled = data['soundEnabled'] as bool? ?? soundEnabled;
    ambientSoundsEnabled =
        data['ambientSoundsEnabled'] as bool? ?? ambientSoundsEnabled;
    hapticsEnabled = data['hapticsEnabled'] as bool? ?? hapticsEnabled;
    reminderEnabled = data['reminderEnabled'] as bool? ?? reminderEnabled;
    sessionBackgroundEnabled =
        data['sessionBackgroundEnabled'] as bool? ?? sessionBackgroundEnabled;
    dailyTargetMinutes =
        (data['dailyTargetMinutes'] as num?)?.toInt() ?? dailyTargetMinutes;
    selectedFocusTarget =
        (data['selectedFocusTarget'] as num?)?.toInt() ?? selectedFocusTarget;
    totalFocusMinutes =
        (data['totalFocusMinutes'] as num?)?.toInt() ?? totalFocusMinutes;
    bestSessionSeconds =
        (data['bestSessionSeconds'] as num?)?.toInt() ?? bestSessionSeconds;
    bits = (data['bits'] as num?)?.toInt() ?? bits;
    totalPulls = (data['totalPulls'] as num?)?.toInt() ?? totalPulls;
    pityCounter = (data['pityCounter'] as num?)?.toInt() ?? pityCounter;
    hasCompletedTutorial =
        data['hasCompletedTutorial'] as bool? ?? hasCompletedTutorial;
    themeMode = _themeModeFromName(data['themeMode'] as String?);
    accentStyle = _accentStyleFromName(
      data['accentStyle'] as String? ?? data['backgroundStyle'] as String?,
    );
    _lastPulledCharacterId = data['lastPulledCharacterId'] as String?;
    _applySessionHistoryData(data['sessionHistory']);
    lastFocusResult = null;
    lastPulledCharacters = <GameCharacter>[];
  }

  List<Map<String, Object?>> _sessionHistoryData() {
    return _sessionHistory
        .map((FocusSessionRecord record) => record.toJson())
        .toList(growable: false);
  }

  void _applySessionHistoryData(Object? value) {
    if (value is! List) {
      return;
    }

    final List<FocusSessionRecord> parsed = value
        .map(FocusSessionRecord.fromJson)
        .whereType<FocusSessionRecord>()
        .toList();
    // Sort defensively: the stored order should already be newest-first, but a
    // hand-edited or merged document shouldn't scramble the log or the cap.
    parsed.sort(
      (FocusSessionRecord a, FocusSessionRecord b) =>
          b.completedAt.compareTo(a.completedAt),
    );

    _sessionHistory
      ..clear()
      ..addAll(parsed.take(sessionHistoryLimit));
  }

  Future<void> _persistLocalCache() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sessionEnabledKey, isLoggedIn);

    if (!isLoggedIn) {
      await prefs.remove(_sessionEmailKey);
      await prefs.remove(_sessionNameKey);
      await prefs.remove(_sessionUserIdKey);
      await prefs.remove(_progressCacheKey);
      return;
    }

    await prefs.setString(_sessionEmailKey, playerEmail);
    await prefs.setString(_sessionNameKey, playerName);
    if (playerId != null && playerId!.isNotEmpty) {
      await prefs.setString(_sessionUserIdKey, playerId!);
    } else {
      await prefs.remove(_sessionUserIdKey);
    }
    await prefs.setString(_progressCacheKey, jsonEncode(_localProgressData()));
  }

  Future<void> _clearLocalCache() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionEnabledKey);
    await prefs.remove(_sessionEmailKey);
    await prefs.remove(_sessionNameKey);
    await prefs.remove(_sessionUserIdKey);
    await prefs.remove(_progressCacheKey);
  }

  Map<String, Object?> _localProgressData() {
    return <String, Object?>{
      'collection': _collection,
      'difficulty': difficulty.name,
      'soundEnabled': soundEnabled,
      'ambientSoundsEnabled': ambientSoundsEnabled,
      'hapticsEnabled': hapticsEnabled,
      'reminderEnabled': reminderEnabled,
      'sessionBackgroundEnabled': sessionBackgroundEnabled,
      'dailyTargetMinutes': dailyTargetMinutes,
      'selectedFocusTarget': selectedFocusTarget,
      'totalFocusMinutes': totalFocusMinutes,
      'bestSessionSeconds': bestSessionSeconds,
      'bits': bits,
      'totalPulls': totalPulls,
      'pityCounter': pityCounter,
      'hasCompletedTutorial': hasCompletedTutorial,
      'themeMode': themeMode.name,
      'accentStyle': accentStyle.name,
      'lastPulledCharacterId': _lastPulledCharacterId,
      'sessionHistory': _sessionHistoryData(),
      'updatedAtClient': _progressUpdatedAt,
    };
  }

  Future<void> _syncProfileToFirebase({
    required User user,
    required String resolvedName,
    required String email,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'displayName': resolvedName,
        'email': email,
        'provider': 'password',
        'lastLoginAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException {
      // Keep the authenticated session active even if profile sync is offline.
    }
  }

  Future<bool> _canRecoverFromNetworkSignInFailure(
    FirebaseAuthException error, {
    required String email,
  }) async {
    if (error.code != 'network-request-failed') {
      return false;
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String cachedEmail = (prefs.getString(_sessionEmailKey) ?? '')
        .trim()
        .toLowerCase();
    return cachedEmail.isNotEmpty && cachedEmail == email.trim().toLowerCase();
  }

  Future<String?> _cachedNameForEmail(String email) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String normalizedEmail = email.trim().toLowerCase();
    final String cachedEmail = (prefs.getString(_sessionEmailKey) ?? '')
        .trim()
        .toLowerCase();
    if (cachedEmail != normalizedEmail) {
      return null;
    }
    final String cachedName = (prefs.getString(_sessionNameKey) ?? '').trim();
    return cachedName.isEmpty ? null : cachedName;
  }

  void _resetProgress() {
    _collection.clear();
    _sessionHistory.clear();
    difficulty = AppDifficulty.highSchool;
    soundEnabled = true;
    ambientSoundsEnabled = true;
    hapticsEnabled = true;
    reminderEnabled = true;
    sessionBackgroundEnabled = true;
    dailyTargetMinutes = 90;
    selectedFocusTarget = 25;
    isFocusActive = false;
    isFocusPaused = false;
    currentSessionSeconds = 0;
    totalFocusMinutes = 0;
    bestSessionSeconds = 0;
    bits = 0;
    totalPulls = 0;
    pityCounter = 0;
    hasCompletedTutorial = false;
    isTutorialActive = false;
    tutorialStep = TutorialStep.inventoryWelcome;
    lastFocusResult = null;
    lastPulledCharacter = null;
    lastPulledCharacters = <GameCharacter>[];
    themeMode = ThemeMode.light;
    accentStyle = AppAccentStyle.mint;
    _lockedRewardPerMinute = null;
    _progressUpdatedAt = 0;
  }

  AppDifficulty _difficultyFromName(String? value) {
    return AppDifficulty.values.firstWhere(
      (AppDifficulty difficulty) => difficulty.name == value,
      orElse: () => AppDifficulty.highSchool,
    );
  }

  ThemeMode _themeModeFromName(String? value) {
    return ThemeMode.values.firstWhere(
      (ThemeMode mode) => mode.name == value,
      orElse: () => ThemeMode.light,
    );
  }

  AppAccentStyle _accentStyleFromName(String? value) {
    return AppAccentStyle.values.firstWhere(
      (AppAccentStyle style) => style.name == value,
      orElse: () => AppAccentStyle.mint,
    );
  }

  CharacterRarity _rollRarity({required bool guaranteedLegendary}) {
    if (guaranteedLegendary) {
      return CharacterRarity.legendary;
    }

    final int total = _availableRarityWeights.values.fold(
      0,
      (int a, int b) => a + b,
    );
    int roll = _random.nextInt(total);
    for (final MapEntry<CharacterRarity, int> entry
        in _availableRarityWeights.entries) {
      if (roll < entry.value) {
        return entry.key;
      }
      roll -= entry.value;
    }
    throw StateError('No pullable character rarity available');
  }

  String _sessionLabel(int seconds) {
    if (seconds >= 3600) {
      return 'Deep focus';
    }
    if (seconds >= 2700) {
      return 'Locked in';
    }
    if (seconds >= 1500) {
      return 'Solid session';
    }
    if (seconds >= 600) {
      return 'Warm-up';
    }
    return 'Quick burst';
  }
}
