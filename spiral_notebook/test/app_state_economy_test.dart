import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:spiral_notebook/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('focus reward is locked to the difficulty chosen at session start', () {
    final SpiralAppState appState = SpiralAppState();
    addTearDown(appState.dispose);

    // Start a long session on the lowest-reward tier (College = 3 bits/min).
    appState.setDifficulty(AppDifficulty.college);
    appState.startFocusSession();
    appState.currentSessionSeconds = 60 * 60; // 60 minutes elapsed

    // Exploit attempt: switch to the highest-reward tier right before collecting.
    appState.setDifficulty(AppDifficulty.elementary); // 15 bits/min

    final FocusSessionResult? result = appState.finishFocusSession();

    // Payout must use the locked College rate (3/min), NOT Elementary (15/min):
    // 60 * 3 = 180, +15 (>=20 min) +25 (>=45 min) = 220.
    expect(result, isNotNull);
    expect(result!.rewardsEarned, 220);
    expect(appState.bits, 220);
  });

  test('reward preview reflects the live difficulty before a session', () {
    final SpiralAppState appState = SpiralAppState();
    addTearDown(appState.dispose);

    appState.setFocusTarget(60);

    appState.setDifficulty(AppDifficulty.elementary); // 15/min
    // 60 * 15 = 900, +15 +25 = 940.
    expect(appState.currentRewardPreview, 940);

    appState.setDifficulty(AppDifficulty.college); // 3/min
    // 60 * 3 = 180, +15 +25 = 220.
    expect(appState.currentRewardPreview, 220);
  });

  test('phone stand removal pauses and replacement resumes a session', () {
    final SpiralAppState appState = SpiralAppState();
    addTearDown(appState.dispose);

    appState.updatePhoneStandConnectionStatus(
      PhoneStandConnectionStatus.connected,
    );
    appState.applyPhoneStandMessage('STATE,phone_present=1,value=12000');
    appState.startFocusSession();
    appState.currentSessionSeconds = 90;

    appState.applyPhoneStandMessage('PHONE_OFF,value=1000');

    expect(appState.isFocusActive, isTrue);
    expect(appState.isFocusPaused, isTrue);
    expect(appState.isFocusPausedByPhoneStand, isTrue);

    appState.applyPhoneStandMessage('PHONE_ON,value=13000');

    expect(appState.isFocusActive, isTrue);
    expect(appState.isFocusPaused, isFalse);
    expect(appState.isFocusPausedByPhoneStand, isFalse);
    expect(appState.currentSessionSeconds, 90);
  });

  test('a guaranteed (pity) legendary resets the pity counter to zero', () {
    final SpiralAppState appState = SpiralAppState();
    addTearDown(appState.dispose);

    appState.bits = SpiralAppState.pullCost * 5;
    appState.pityCounter = SpiralAppState.pityLimit - 1; // one short of pity

    final List<GameCharacter>? results = appState.pullCharacters(1);

    // The pull crosses the pity limit, so it is a guaranteed legendary and the
    // counter resets cleanly to 0.
    expect(results, isNotNull);
    expect(results!.single.rarity, CharacterRarity.legendary);
    expect(appState.pityCounter, 0);
  });

  test('pity accrues by exactly one per pull when no legendary is hit', () {
    final SpiralAppState appState = SpiralAppState();
    addTearDown(appState.dispose);

    appState.bits = SpiralAppState.pullCost * 20;
    appState.pityCounter = 0;

    // Pull singles until a legendary happens to drop, asserting that until then
    // pity increments by exactly 1 each pull (no spurious batch reset/skip).
    int expected = 0;
    for (int i = 0; i < 10; i += 1) {
      final List<GameCharacter>? results = appState.pullCharacters(1);
      expect(results, isNotNull);
      if (results!.single.rarity == CharacterRarity.legendary) {
        expect(appState.pityCounter, 0);
        break;
      }
      expected += 1;
      expect(appState.pityCounter, expected);
    }
  });
}
