import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spiral_notebook/app_state.dart';
import 'package:spiral_notebook/screens/loginscreen.dart';

import 'support/character_roster.dart';

class _VerificationState extends SpiralAppState {
  _VerificationState() : super(roster: testCharacterRoster) {
    verificationEmail = 'new@example.com';
  }

  int checks = 0;
  int resends = 0;

  @override
  Future<bool> checkEmailVerification() async {
    checks += 1;
    return false;
  }

  @override
  Future<void> resendVerificationEmail() async {
    resends += 1;
  }

  @override
  Future<void> cancelPendingVerification() async {
    verificationEmail = null;
    notifyListeners();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('pending verification offers check, resend, and account switch', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final _VerificationState appState = _VerificationState();
    addTearDown(appState.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: AnimatedBuilder(
          animation: appState,
          builder: (BuildContext context, Widget? child) =>
              LoginScreen(appState: appState),
        ),
      ),
    );

    expect(find.text('Verify your email'), findsOneWidget);
    expect(find.textContaining('new@example.com'), findsOneWidget);

    final Finder resend = find.text('Resend verification email');
    await tester.ensureVisible(resend);
    await tester.tap(resend);
    await tester.pump();
    expect(appState.resends, 1);
    expect(find.textContaining('Verification email sent'), findsOneWidget);

    final Finder check = find.text("I've verified my email");
    await tester.ensureVisible(check);
    await tester.tap(check);
    await tester.pump();
    expect(appState.checks, 1);
    expect(find.textContaining('Email is not verified yet'), findsOneWidget);

    final Finder switchAccount = find.text('Use another account');
    await tester.ensureVisible(switchAccount);
    await tester.tap(switchAccount);
    await tester.pump();
    expect(find.text('Sign in to Focugacha'), findsOneWidget);
    expect(find.text('Verify your email'), findsNothing);
  });
}
