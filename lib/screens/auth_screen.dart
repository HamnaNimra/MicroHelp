import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/analytics_service.dart';
import 'complete_profile_screen.dart';
import 'home_screen.dart';
import 'sign_up_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _loading = false;
  String? _error;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: SelectableText(
                      _error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Enter your email' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outlined),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Enter your password' : null,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _loading ? null : _showForgotPasswordDialog,
                    child: const Text('Forgot password?'),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _loading ? null : _submitSignIn,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Sign In'),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('or'),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),
                if (context.read<AuthService>().canSignInWithGoogle)
                  OutlinedButton.icon(
                    onPressed: _loading ? null : _signInWithGoogle,
                    icon: const Icon(Icons.g_mobiledata, size: 24),
                    label: const Text('Continue with Google'),
                  ),
                if (context.read<AuthService>().canSignInWithGoogle)
                  const SizedBox(height: 12),
                if (context.read<AuthService>().canSignInWithApple)
                  OutlinedButton.icon(
                    onPressed: _loading ? null : _signInWithApple,
                    icon: const Icon(Icons.apple, size: 24),
                    label: const Text('Continue with Apple'),
                  ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const SignUpScreen(),
                      ),
                    );
                  },
                  child: const Text("Don't have an account? Sign Up"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _friendlyAuthError(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return 'That email address is not valid.';
        case 'user-disabled':
          return 'This account has been disabled. Contact support.';
        case 'user-not-found':
          return 'No account found with that email. Try signing up instead.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Invalid email or password. Please try again.';
        case 'email-already-in-use':
          return 'An account already exists with that email. Try signing in instead.';
        case 'account-exists-with-different-credential':
          return 'An account already exists with that email using a different sign-in method. '
              'Sign in with your original method, then link this provider in Edit Profile.';
        case 'credential-already-in-use':
          return 'This credential is already linked to another account.';
        case 'weak-password':
          return 'Password is too weak. Use at least 6 characters.';
        case 'too-many-requests':
          return 'Too many attempts. Please wait a moment and try again.';
        case 'network-request-failed':
          return 'Network error. Check your connection and try again.';
        default:
          return e.message ?? 'Authentication failed. Please try again.';
      }
    }
    return 'Something went wrong. Please try again.';
  }

  void _navigateAfterAuth(UserModel? user, String uid, String? displayName) {
    if (user != null && !context.read<AuthService>().isProfileComplete(user)) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => CompleteProfileScreen(
            uid: uid,
            prefillName: displayName,
          ),
        ),
        (r) => false,
      );
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (r) => false,
      );
    }
  }

  void _showForgotPasswordDialog() {
    final resetEmailCtrl = TextEditingController(text: _emailController.text);
    bool sending = false;
    String? message;
    bool success = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Reset password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter your email address and we\'ll send you a link to reset your password.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: resetEmailCtrl,
                keyboardType: TextInputType.emailAddress,
                enabled: !sending && !success,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.email_outlined),
                  errorText: message != null && !success ? message : null,
                ),
              ),
              if (success && message != null) ...[
                const SizedBox(height: 12),
                Text(
                  message!,
                  style: TextStyle(color: Colors.green[700]),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(success ? 'Done' : 'Cancel'),
            ),
            if (!success)
              FilledButton(
                onPressed: sending
                    ? null
                    : () async {
                        final email = resetEmailCtrl.text.trim();
                        if (email.isEmpty) {
                          setDialogState(() => message = 'Enter your email');
                          return;
                        }
                        setDialogState(() {
                          sending = true;
                          message = null;
                        });
                        try {
                          await context
                              .read<AuthService>()
                              .sendPasswordResetEmail(email);
                          setDialogState(() {
                            sending = false;
                            success = true;
                            message =
                                'Password reset email sent! Check your inbox.';
                          });
                        } on FirebaseAuthException catch (e) {
                          setDialogState(() {
                            sending = false;
                            switch (e.code) {
                              case 'user-not-found':
                                message =
                                    'No account found with that email.';
                              case 'invalid-email':
                                message = 'That email address is not valid.';
                              case 'too-many-requests':
                                message =
                                    'Too many attempts. Try again later.';
                              default:
                                message =
                                    e.message ?? 'Failed to send reset email.';
                            }
                          });
                        } catch (_) {
                          setDialogState(() {
                            sending = false;
                            message = 'Something went wrong. Please try again.';
                          });
                        }
                      },
                child: sending
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send reset link'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitSignIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final auth = context.read<AuthService>();
      final cred = await auth.signInWithEmail(
          _emailController.text.trim(), _passwordController.text);
      if (cred?.user != null) {
        final user = await auth.getOrCreateUser(cred!.user!);
        if (!mounted) return;
        final analytics = context.read<AnalyticsService>();
        analytics.logLogin(method: 'email');
        analytics.setUserProperties(userId: cred.user!.uid);
        _navigateAfterAuth(user, cred.user!.uid, cred.user!.displayName);
      }
    } catch (e) {
      if (mounted) setState(() => _error = _friendlyAuthError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _socialSignIn(Future<UserCredential?> Function() signIn, String method) async {
    setState(() { _loading = true; _error = null; });
    try {
      final auth = context.read<AuthService>();
      final cred = await signIn();
      if (cred?.user != null) {
        final user = await auth.getOrCreateUser(cred!.user!);
        if (!mounted) return;
        final analytics = context.read<AnalyticsService>();
        analytics.logLogin(method: method);
        analytics.setUserProperties(userId: cred.user!.uid);
        _navigateAfterAuth(user, cred.user!.uid, cred.user!.displayName);
      }
    } catch (e) {
      if (mounted) setState(() => _error = _friendlyAuthError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() =>
      _socialSignIn(context.read<AuthService>().signInWithGoogle, 'google');

  Future<void> _signInWithApple() =>
      _socialSignIn(context.read<AuthService>().signInWithApple, 'apple');
}
