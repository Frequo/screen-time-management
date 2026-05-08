import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spiral_notebook/theme/app_palette.dart';

enum AppDifficulty { elementary, middle, highSchool, college }

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
    AppDifficulty.elementary => 6,
    AppDifficulty.middle => 5,
    AppDifficulty.highSchool => 4,
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

enum CharacterRarity { common, rare, epic, legendary }

extension CharacterRarityDetails on CharacterRarity {
  String get label => switch (this) {
    CharacterRarity.common => 'Common',
    CharacterRarity.rare => 'Rare',
    CharacterRarity.epic => 'Epic',
    CharacterRarity.legendary => 'Legendary',
  };

  Color get color => switch (this) {
    CharacterRarity.common => AppPalette.sky,
    CharacterRarity.rare => AppPalette.mint,
    CharacterRarity.epic => AppPalette.tangerine,
    CharacterRarity.legendary => AppPalette.sun,
  };
}

class GameCharacter {
  const GameCharacter({
    required this.id,
    required this.name,
    required this.title,
    required this.rarity,
    required this.description,
    required this.accent,
    this.portraitAsset = 'assets/overview.png',
    this.mainAsset = 'assets/fullview.png',
  });

  final String id;
  final String name;
  final String title;
  final CharacterRarity rarity;
  final String description;
  final Color accent;
  final String portraitAsset;
  final String mainAsset;
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

class SpiralAppState extends ChangeNotifier {
  SpiralAppState({this.firebaseEnabled = false}) {
    unawaited(_hydrateLocalCache());

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
  static const String _sessionEmailKey = 'session.email';
  static const String _sessionNameKey = 'session.name';
  static const String _sessionUserIdKey = 'session.userId';
  static const String _progressCacheKey = 'progress.cache';
  static const String _sessionEnabledKey = 'session.enabled';

  final Random _random = Random();
  final List<GameCharacter> roster = _characterRoster;
  final Map<String, int> _collection = <String, int>{};
  final bool firebaseEnabled;

  StreamSubscription<User?>? _authSubscription;
  Timer? _focusTicker;
  bool _isHydratingProgress = false;

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
  int bits = 120;
  int totalPulls = 0;
  int pityCounter = 0;
  FocusSessionResult? lastFocusResult;
  GameCharacter? lastPulledCharacter;
  List<GameCharacter> lastPulledCharacters = <GameCharacter>[];

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

  int get dailyProgressMinutes => min(totalFocusMinutes, dailyTargetMinutes);

  double get dailyProgress =>
      dailyTargetMinutes == 0 ? 0 : dailyProgressMinutes / dailyTargetMinutes;

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
        final String uid = user.uid;
        await user.delete();
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .delete();
        } on FirebaseException {
          // Auth deletion is the source of truth; profile cleanup may be
          // blocked by security rules after the auth user is removed.
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

  void startFocusSession() {
    if (isFocusActive && !isFocusPaused) {
      return;
    }

    if (!isFocusPaused) {
      currentSessionSeconds = 0;
    }
    isFocusActive = true;
    isFocusPaused = false;
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
    currentSessionSeconds = 0;
    notifyListeners();
    _persistProgress();
    return result;
  }

  void cancelFocusSession() {
    _stopTicker();
    isFocusActive = false;
    isFocusPaused = false;
    currentSessionSeconds = 0;
    notifyListeners();
  }

  void pauseFocusSession() {
    if (!isFocusActive) {
      return;
    }

    _stopTicker();
    isFocusActive = true;
    isFocusPaused = true;
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
    for (final GameCharacter character in roster) {
      if (character.id == id) {
        return character;
      }
    }
    return null;
  }

  GameCharacter? pullCharacter() {
    final List<GameCharacter>? results = pullCharacters(1);
    if (results == null || results.isEmpty) {
      return null;
    }
    return results.first;
  }

  List<GameCharacter>? pullCharacters(int count) {
    if (count <= 0 || bits < pullCost * count) {
      return null;
    }

    final List<GameCharacter> results = <GameCharacter>[];
    bool batchHasLegendary = false;
    for (int index = 0; index < count; index += 1) {
      final GameCharacter pulled = _performPull();
      results.add(pulled);
      if (pulled.rarity == CharacterRarity.legendary) {
        batchHasLegendary = true;
      }
    }

    if (count > 1 && batchHasLegendary) {
      pityCounter = 0;
    }

    lastPulledCharacter = results.last;
    lastPulledCharacters = List<GameCharacter>.unmodifiable(results);
    notifyListeners();
    _persistProgress();
    return results;
  }

  GameCharacter _performPull() {
    bits -= pullCost;
    totalPulls += 1;
    pityCounter += 1;

    final bool guaranteedLegendary = pityCounter >= pityLimit;
    final CharacterRarity rarity = _rollRarity(
      guaranteedLegendary: guaranteedLegendary,
    );
    final List<GameCharacter> rarityPool = charactersByRarity(rarity);
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

    int reward = wholeMinutes * difficulty.rewardPerMinute;
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
    super.dispose();
  }

  void _stopTicker() {
    _focusTicker?.cancel();
    _focusTicker = null;
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
    await _persistLocalCache();
    await _loadProgressFromFirebase();
  }

  Future<void> _loadProgressFromFirebase() async {
    final String? uid = playerId;
    if (!firebaseEnabled || uid == null) {
      return;
    }

    _isHydratingProgress = true;
    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final Map<String, dynamic>? data = snapshot.data();
      if (data == null) {
        await _persistProgress(force: true);
        return;
      }

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
      themeMode = _themeModeFromName(data['themeMode'] as String?);
      accentStyle = _accentStyleFromName(
        data['accentStyle'] as String? ?? data['backgroundStyle'] as String?,
      );
      lastPulledCharacter = findCharacterById(
        data['lastPulledCharacterId'] as String? ?? '',
      );
      await _persistLocalCache();
      notifyListeners();
    } on FirebaseException {
      await _hydrateProgressFromLocalCache();
    } finally {
      _isHydratingProgress = false;
    }
  }

  Future<void> _persistProgress({bool force = false}) async {
    await _persistLocalCache();
    if (_isHydratingProgress && !force) {
      return;
    }
    if (!firebaseEnabled || playerId == null) {
      return;
    }
    await FirebaseFirestore.instance.collection('users').doc(playerId).set({
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
      'themeMode': themeMode.name,
      'accentStyle': accentStyle.name,
      'lastPulledCharacterId': lastPulledCharacter?.id,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _hydrateLocalCache() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool hasSession = prefs.getBool(_sessionEnabledKey) ?? false;

    if (hasSession && !isLoggedIn) {
      playerName = prefs.getString(_sessionNameKey) ?? '';
      playerEmail = prefs.getString(_sessionEmailKey) ?? '';
      playerId = prefs.getString(_sessionUserIdKey);
      isLoggedIn = playerEmail.isNotEmpty;
      await _hydrateProgressFromLocalCache(preferences: prefs);
      notifyListeners();
    }
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

    final Map<String, dynamic> data = jsonDecode(raw) as Map<String, dynamic>;
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
    themeMode = _themeModeFromName(data['themeMode'] as String?);
    accentStyle = _accentStyleFromName(
      data['accentStyle'] as String? ?? data['backgroundStyle'] as String?,
    );
    lastPulledCharacter = findCharacterById(
      data['lastPulledCharacterId'] as String? ?? '',
    );
    lastFocusResult = null;
    lastPulledCharacters = <GameCharacter>[];
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
      'themeMode': themeMode.name,
      'accentStyle': accentStyle.name,
      'lastPulledCharacterId': lastPulledCharacter?.id,
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
    bits = 120;
    totalPulls = 0;
    pityCounter = 0;
    lastFocusResult = null;
    lastPulledCharacter = null;
    lastPulledCharacters = <GameCharacter>[];
    themeMode = ThemeMode.light;
    accentStyle = AppAccentStyle.mint;
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

    final int roll = _random.nextInt(1000);
    if (roll < 10) {
      return CharacterRarity.legendary;
    }
    if (roll < 100) {
      return CharacterRarity.epic;
    }
    if (roll < 320) {
      return CharacterRarity.rare;
    }
    return CharacterRarity.common;
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

const List<GameCharacter> _characterRoster = <GameCharacter>[
  GameCharacter(
    id: 'mina-sidewalk-sketcher',
    name: 'Minato Vale',
    title: 'Sidewalk Sketcher',
    rarity: CharacterRarity.common,
    description:
        'Turns every study break into a chalk mural full of tiny city cats.',
    accent: Color(0xFF83B5D1),
  ),
  GameCharacter(
    id: 'theo-trainstop-coder',
    name: 'Theo Quill',
    title: 'Trainstop Coder',
    rarity: CharacterRarity.common,
    description:
        'Builds timer widgets between station arrivals and always ships on time.',
    accent: Color(0xFF799EC2),
  ),
  GameCharacter(
    id: 'june-courier',
    name: 'Juniper Rush',
    title: 'Bubble Tea Courier',
    rarity: CharacterRarity.common,
    description:
        'Knows every shortcut in the district and every cafe with open outlets.',
    accent: Color(0xFF97D7B6),
  ),
  GameCharacter(
    id: 'nico-corner-drummer',
    name: 'Nico Static',
    title: 'Corner Drummer',
    rarity: CharacterRarity.common,
    description:
        'Keeps your focus rhythm steady with tabletop beats and subway grooves.',
    accent: Color(0xFFF2B36D),
  ),
  GameCharacter(
    id: 'yara-bookshop-scout',
    name: 'Yara Finch',
    title: 'Bookshop Scout',
    rarity: CharacterRarity.common,
    description:
        'Can find the quietest reading nook in any neighborhood within seconds.',
    accent: Color(0xFF90B5A4),
  ),
  GameCharacter(
    id: 'eli-park-runner',
    name: 'Eli Mercer',
    title: 'Park Runner',
    rarity: CharacterRarity.common,
    description:
        'Uses sunrise laps to reset before classes and talks only in split times.',
    accent: Color(0xFF8BCF9B),
  ),
  GameCharacter(
    id: 'sora-night-vendor',
    name: 'Sora Ember',
    title: 'Night Market Vendor',
    rarity: CharacterRarity.common,
    description:
        'Sells paper lanterns that glow brighter after every finished task list.',
    accent: Color(0xFFFFB36C),
  ),
  GameCharacter(
    id: 'ava-busker-bloom',
    name: 'Ava Lark',
    title: 'Busker Bloom',
    rarity: CharacterRarity.common,
    description:
        'Plays bright pop hooks that somehow make even math worksheets feel lighter.',
    accent: Color(0xFFF29D94),
  ),
  GameCharacter(
    id: 'leo-crosswalk-captain',
    name: 'Leo Voss',
    title: 'Crosswalk Captain',
    rarity: CharacterRarity.common,
    description:
        'Keeps the whole block moving with a whistle, hand signs, and perfect timing.',
    accent: Color(0xFFE2C15F),
  ),
  GameCharacter(
    id: 'hana-rooftop-gardener',
    name: 'Hana Reed',
    title: 'Rooftop Gardener',
    rarity: CharacterRarity.common,
    description:
        'Grows tomatoes, mint, and impossible patience above a noisy avenue.',
    accent: Color(0xFF7AC792),
  ),
  GameCharacter(
    id: 'owen-cafe-lead',
    name: 'Owen Slate',
    title: 'Cafe Shift Lead',
    rarity: CharacterRarity.common,
    description:
        'Can remember eight custom orders and your exam schedule at the same time.',
    accent: Color(0xFFC08B6C),
  ),
  GameCharacter(
    id: 'mira-library-navigator',
    name: 'Mira Sol',
    title: 'Library Navigator',
    rarity: CharacterRarity.common,
    description:
        'Guides lost freshmen through stacks, deadlines, and printer disasters.',
    accent: Color(0xFF9BA9CF),
  ),
  GameCharacter(
    id: 'ben-skate-loop',
    name: 'Bennett Loop',
    title: 'Skate Loop Kid',
    rarity: CharacterRarity.common,
    description:
        'Can land a clean kickflip only after he finishes his homework checklist.',
    accent: Color(0xFF80B5C1),
  ),
  GameCharacter(
    id: 'zoe-raincoat-dreamer',
    name: 'Zoe Nightjar',
    title: 'Raincoat Dreamer',
    rarity: CharacterRarity.common,
    description:
        'Collects storm sounds and writes essays that feel like midnight sidewalks.',
    accent: Color(0xFF91A8D4),
  ),
  GameCharacter(
    id: 'ian-repair-club-ace',
    name: 'Ian Calder',
    title: 'Repair Club Ace',
    rarity: CharacterRarity.common,
    description:
        'Can fix a wobbly desk, a snapped cable, and your morale before lunch.',
    accent: Color(0xFFA5B7C4),
  ),
  GameCharacter(
    id: 'lila-lantern-walker',
    name: 'Lila Wren',
    title: 'Lantern Walker',
    rarity: CharacterRarity.common,
    description:
        'Stays out late mapping alley lights and the best routes home from cram school.',
    accent: Color(0xFFFFA28A),
  ),
  GameCharacter(
    id: 'celine-neon-barista',
    name: 'Celine Lux',
    title: 'Neon Barista',
    rarity: CharacterRarity.rare,
    description:
        'Steams perfect milk art while juggling playlists, shifts, and side projects.',
    accent: Color(0xFF40B7B3),
  ),
  GameCharacter(
    id: 'felix-metro-dj',
    name: 'Felix Echo',
    title: 'Metro DJ',
    rarity: CharacterRarity.rare,
    description:
        'Turns late train announcements into the backbone of impossible club mixes.',
    accent: Color(0xFF36A4A2),
  ),
  GameCharacter(
    id: 'priya-studio-sprinter',
    name: 'Priya Vale',
    title: 'Studio Sprinter',
    rarity: CharacterRarity.rare,
    description:
        'Finishes design critiques faster than anyone and still has time to help.',
    accent: Color(0xFF2CB59D),
  ),
  GameCharacter(
    id: 'mateo-arcade-tactician',
    name: 'Mateo Grid',
    title: 'Arcade Tactician',
    rarity: CharacterRarity.rare,
    description:
        'Tracks combo routes, lab timers, and cafeteria lines with equal precision.',
    accent: Color(0xFF21B2A0),
  ),
  GameCharacter(
    id: 'iris-signal-hacker',
    name: 'Iris Kade',
    title: 'Signal Hacker',
    rarity: CharacterRarity.rare,
    description:
        'Makes ancient projectors behave and never explains how she learned that.',
    accent: Color(0xFF4AB4C8),
  ),
  GameCharacter(
    id: 'ruby-sticker-poet',
    name: 'Ruby Verse',
    title: 'Sticker Poet',
    rarity: CharacterRarity.rare,
    description:
        'Leaves tiny motivational lines hidden on notebooks all over the city.',
    accent: Color(0xFF3FA89D),
  ),
  GameCharacter(
    id: 'damon-bike-messenger',
    name: 'Damon Swift',
    title: 'Bike Messenger',
    rarity: CharacterRarity.rare,
    description:
        'Treats every deadline like a checkpoint race through afternoon traffic.',
    accent: Color(0xFF3DC993),
  ),
  GameCharacter(
    id: 'harper-street-stylist',
    name: 'Harper Rue',
    title: 'Street Stylist',
    rarity: CharacterRarity.rare,
    description:
        'Can thrift a whole outfit around one bright scarf and a train pass.',
    accent: Color(0xFF53AA80),
  ),
  GameCharacter(
    id: 'kira-window-painter',
    name: 'Kira Bloom',
    title: 'Window Painter',
    rarity: CharacterRarity.rare,
    description:
        'Fills storefront glass with city scenes that vanish by the next rainstorm.',
    accent: Color(0xFF44B6AE),
  ),
  GameCharacter(
    id: 'adrian-courtyard-coach',
    name: 'Adrian Pike',
    title: 'Courtyard Coach',
    rarity: CharacterRarity.rare,
    description:
        'Runs lunchtime drills that somehow improve both posture and confidence.',
    accent: Color(0xFF2EAF94),
  ),
  GameCharacter(
    id: 'nia-newsstand-sage',
    name: 'Nia Marlowe',
    title: 'Newsstand Sage',
    rarity: CharacterRarity.rare,
    description:
        'Always knows the weather, test schedule, and local gossip before sunrise.',
    accent: Color(0xFF3CB8B1),
  ),
  GameCharacter(
    id: 'rowan-tram-guardian',
    name: 'Rowan Drift',
    title: 'Tram Guardian',
    rarity: CharacterRarity.rare,
    description:
        'Keeps late riders calm with dry jokes and suspiciously perfect directions.',
    accent: Color(0xFF2F9F93),
  ),
  GameCharacter(
    id: 'selene-skyline-architect',
    name: 'Selene Arclight',
    title: 'Skyline Architect',
    rarity: CharacterRarity.epic,
    description:
        'Designs rooftop classrooms where the wind sounds like turning notebook pages.',
    accent: Color(0xFFCF7E49),
  ),
  GameCharacter(
    id: 'jasper-midnight-chef',
    name: 'Jasper Noctis',
    title: 'Midnight Chef',
    rarity: CharacterRarity.epic,
    description:
        'Runs a hidden ramen counter that opens only after the city clocks chime.',
    accent: Color(0xFFD26C3E),
  ),
  GameCharacter(
    id: 'talia-festival-director',
    name: 'Talia Sunmark',
    title: 'Festival Director',
    rarity: CharacterRarity.epic,
    description:
        'Can light an entire block party with paper lanterns and ruthless scheduling.',
    accent: Color(0xFFDE8850),
  ),
  GameCharacter(
    id: 'quinn-clocktower-engineer',
    name: 'Quinn Brass',
    title: 'Clocktower Engineer',
    rarity: CharacterRarity.epic,
    description:
        'Repairs the old district bells so every hour lands exactly on beat.',
    accent: Color(0xFFBD6B42),
  ),
  GameCharacter(
    id: 'ayla-graffiti-virtuoso',
    name: 'Ayla Chrom',
    title: 'Graffiti Virtuoso',
    rarity: CharacterRarity.epic,
    description:
        'Paints color across gray walls without ever missing a curfew or deadline.',
    accent: Color(0xFFE07A39),
  ),
  GameCharacter(
    id: 'cass-solar-botanist',
    name: 'Cass Aureline',
    title: 'Solar Botanist',
    rarity: CharacterRarity.epic,
    description:
        'Runs a greenhouse on old station roofs powered by scavenged panels.',
    accent: Color(0xFFD28F4C),
  ),
  GameCharacter(
    id: 'victor-rain-district-marshal',
    name: 'Victor Stroud',
    title: 'Rain District Marshal',
    rarity: CharacterRarity.epic,
    description:
        'Keeps storm drains clear, traffic calm, and umbrellas moving like a parade.',
    accent: Color(0xFFC86A2E),
  ),
  GameCharacter(
    id: 'naomi-storyline-producer',
    name: 'Naomi Reeve',
    title: 'Storyline Producer',
    rarity: CharacterRarity.epic,
    description:
        'Directs music videos on the fly with little more than lights and nerve.',
    accent: Color(0xFFD77955),
  ),
  GameCharacter(
    id: 'orion-sandglass-regent',
    name: 'Orion Halcyon',
    title: 'Sandglass Regent',
    rarity: CharacterRarity.legendary,
    description:
        'Rules the invisible hour between distraction and momentum with calm authority.',
    accent: Color(0xFFF0B52A),
  ),
  GameCharacter(
    id: 'freya-citylight-oracle',
    name: 'Freya Lumen',
    title: 'Citylight Oracle',
    rarity: CharacterRarity.legendary,
    description:
        'Reads the glow of apartment windows to tell who is studying and who needs rest.',
    accent: Color(0xFFE7A51F),
  ),
  GameCharacter(
    id: 'atlas-dawnline-captain',
    name: 'Atlas Meridian',
    title: 'Dawnline Captain',
    rarity: CharacterRarity.legendary,
    description:
        'Leads the first train of the day and never lets the city start out of step.',
    accent: Color(0xFFF2BE3A),
  ),
  GameCharacter(
    id: 'vega-celestial-courier',
    name: 'Vega Starling',
    title: 'Celestial Courier',
    rarity: CharacterRarity.legendary,
    description:
        'Delivers sealed messages between rooftops faster than the weather can change.',
    accent: Color(0xFFE9B83A),
  ),
  GameCharacter(
    id: 'lyra-prism-conductor',
    name: 'Lyra Prism',
    title: 'Prism Conductor',
    rarity: CharacterRarity.legendary,
    description:
        'Turns station glass, sunset light, and train noise into color-soaked symphonies.',
    accent: Color(0xFFF3C74B),
  ),
  GameCharacter(
    id: 'solstice-last-bell',
    name: 'Solstice Vale',
    title: 'The Last Bell',
    rarity: CharacterRarity.legendary,
    description:
        'Appears when a long focus session finally clicks and the whole city seems still.',
    accent: Color(0xFFFFD36A),
  ),
];
