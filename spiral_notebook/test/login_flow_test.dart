import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:spiral_notebook/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('creating a new account starts the onboarding tutorial', () async {
    final SpiralAppState appState = SpiralAppState();
    addTearDown(appState.dispose);

    expect(appState.isTutorialActive, isFalse);

    await appState.login(
      email: 'new@example.com',
      password: 'password',
      displayName: 'New User',
      createAccount: true,
    );

    // Onboarding must start even though the reactive auth gate would unmount the
    // login screen the moment isLoggedIn flips — the tutorial is triggered
    // inside login(), not from the (now-unmounted) screen's post-await code.
    expect(appState.isLoggedIn, isTrue);
    expect(appState.isTutorialActive, isTrue);
  });

  test('signing in to an existing account does not start the tutorial', () async {
    final SpiralAppState appState = SpiralAppState();
    addTearDown(appState.dispose);

    await appState.login(
      email: 'returning@example.com',
      password: 'password',
      createAccount: false,
    );

    expect(appState.isLoggedIn, isTrue);
    expect(appState.isTutorialActive, isFalse);
  });
}
