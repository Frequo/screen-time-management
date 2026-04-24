import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spiral_notebook/app_state.dart';
import 'package:spiral_notebook/theme/app_palette.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.appState});

  final SpiralAppState appState;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isSubmitting = false;
  bool _isCreateAccount = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      body: ColoredBox(
        color: theme.scaffoldBackgroundColor,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: theme.cardColor.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: AppPalette.line),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Container(
                                height: 64,
                                width: 64,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppPalette.sky,
                                ),
                                child: const Icon(
                                  Icons.hourglass_bottom_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      'Nexi',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Study Gacha',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          SegmentedButton<bool>(
                            segments: const <ButtonSegment<bool>>[
                              ButtonSegment<bool>(
                                value: false,
                                icon: Icon(Icons.login_rounded),
                                label: Text('Sign in'),
                              ),
                              ButtonSegment<bool>(
                                value: true,
                                icon: Icon(Icons.person_add_alt_1_rounded),
                                label: Text('Create account'),
                              ),
                            ],
                            selected: <bool>{_isCreateAccount},
                            onSelectionChanged: (Set<bool> selection) {
                              setState(() {
                                _isCreateAccount = selection.first;
                                _errorMessage = null;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          if (_isCreateAccount) ...<Widget>[
                            TextField(
                              controller: _nameController,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Display name',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.badge_outlined),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              helperText:
                                  'Uses Firebase email and password auth on configured mobile builds.',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.mail_outline_rounded),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: _isCreateAccount
                                ? TextInputAction.next
                                : TextInputAction.done,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                              ),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                ),
                              ),
                            ),
                          ),
                          if (_isCreateAccount) ...<Widget>[
                            const SizedBox(height: 16),
                            TextField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              decoration: InputDecoration(
                                labelText: 'Confirm password',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(
                                  Icons.verified_user_outlined,
                                ),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword =
                                          !_obscureConfirmPassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          if (_errorMessage != null) ...<Widget>[
                            const SizedBox(height: 12),
                            Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: _isSubmitting ? null : _enterApp,
                            icon: _isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.arrow_forward_rounded),
                            label: Text(
                              _isSubmitting
                                  ? 'Connecting...'
                                  : _isCreateAccount
                                  ? 'Create Nexi account'
                                  : 'Sign in to Nexi',
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/info'),
                            icon: const Icon(Icons.slideshow_rounded),
                            label: const Text('Preview how it works'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _enterApp() async {
    final String rawName = _nameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;
    final String confirmPassword = _confirmPasswordController.text;

    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Enter the email for your Nexi account.';
      });
      return;
    }

    if (password.isEmpty) {
      setState(() {
        _errorMessage = 'Enter your password.';
      });
      return;
    }

    if (_isCreateAccount && rawName.isEmpty) {
      setState(() {
        _errorMessage = 'Choose a display name for the new account.';
      });
      return;
    }

    if (_isCreateAccount && password.length < 6) {
      setState(() {
        _errorMessage = 'Use at least 6 characters for the password.';
      });
      return;
    }

    if (_isCreateAccount && password != confirmPassword) {
      setState(() {
        _errorMessage = 'The password confirmation does not match.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await widget.appState.login(
        displayName: rawName,
        email: email,
        password: password,
        createAccount: _isCreateAccount,
      );
      if (!mounted) {
        return;
      }
      Navigator.pushReplacementNamed(context, '/app');
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = _messageForError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _messageForError(Object error) {
    if (error is FirebaseAuthException) {
      return switch (error.code) {
        'email-already-in-use' => 'That email already has an account.',
        'invalid-email' => 'Enter a valid email address.',
        'invalid-credential' => 'The email or password is incorrect.',
        'user-not-found' => 'No account matches that email.',
        'wrong-password' => 'The password is incorrect.',
        'weak-password' => 'Choose a stronger password.',
        'network-request-failed' =>
          'Network error while contacting Firebase. After one successful sign-in on this device, the app can reopen that same account from the local cache during outages.',
        _ => error.message ?? 'Firebase sign-in failed.',
      };
    }

    return 'Sign-in failed. ${error.toString()}';
  }
}
