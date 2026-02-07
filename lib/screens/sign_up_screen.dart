import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/analytics_service.dart';
import '../widgets/password_strength_meter.dart';
import 'auth_screen.dart';
import 'complete_profile_screen.dart';
import 'home_screen.dart';

const _genderOptions = ['Male', 'Female', 'Non-binary', 'Prefer not to say', 'Other'];

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _neighborhoodCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _genderOtherCtrl = TextEditingController();
  final _birthdayCtrl = TextEditingController();

  bool _loading = false;
  String? _error;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _passwordForMeter = '';
  DateTime? _birthday;
  String? _gender;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _neighborhoodCtrl.dispose();
    _bioCtrl.dispose();
    _genderOtherCtrl.dispose();
    _birthdayCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Welcome header
                Text(
                  'Welcome to MicroHelp!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Create your account to start helping your neighbors.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 24),

                // Error display
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

                // Full name
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outlined),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email address',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter your email';
                    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                    if (!emailRegex.hasMatch(v.trim())) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password with show/hide
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  onChanged: (v) => setState(() => _passwordForMeter = v),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter a password';
                    if (v.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                // Password strength meter
                PasswordStrengthMeter(password: _passwordForMeter),
                const SizedBox(height: 16),

                // Confirm password with show/hide
                TextFormField(
                  controller: _confirmPasswordCtrl,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () => setState(
                          () => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Confirm your password';
                    if (v != _passwordCtrl.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Birthday
                GestureDetector(
                  onTap: _pickBirthday,
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _birthdayCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Birthday',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.cake_outlined),
                        hintText: 'Tap to select',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      validator: (_) {
                        if (_birthday == null) return 'Select your birthday';
                        if (_calculateAge(_birthday!) < 18) {
                          return 'You must be at least 18 years old';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Gender dropdown
                DropdownButtonFormField<String>(
                  initialValue: _gender,
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.people_outlined),
                  ),
                  items: _genderOptions
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) => setState(() => _gender = v),
                ),

                // "Other" gender text field
                if (_gender == 'Other') ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _genderOtherCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Please specify',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.edit_outlined),
                    ),
                    validator: (v) {
                      if (_gender == 'Other' &&
                          (v == null || v.trim().isEmpty)) {
                        return 'Please specify your gender';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 16),

                // Neighborhood / Postal code
                TextFormField(
                  controller: _neighborhoodCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Neighborhood or postal code',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on_outlined),
                    helperText: 'Helps connect you with nearby neighbors',
                  ),
                ),
                const SizedBox(height: 16),

                // Short bio
                TextFormField(
                  controller: _bioCtrl,
                  maxLines: 3,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    labelText: 'Short bio (optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.info_outlined),
                    hintText: 'Tell your neighbors a bit about yourself...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 8),

                // Terms of Service checkbox
                FormField<bool>(
                  initialValue: _agreedToTerms,
                  validator: (v) =>
                      (v != true) ? 'You must agree to continue' : null,
                  builder: (field) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _agreedToTerms,
                            onChanged: (v) {
                              setState(() => _agreedToTerms = v ?? false);
                              field.didChange(v);
                            },
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text.rich(
                                TextSpan(
                                  text: 'I agree to the ',
                                  children: [
                                    TextSpan(
                                      text: 'Terms of Service',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                    const TextSpan(text: ' and '),
                                    TextSpan(
                                      text: 'Privacy Policy',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (field.hasError)
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Text(
                            field.errorText!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Privacy note
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Your info stays private and secure.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),

                // Sign Up button
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create Account'),
                ),

                // Social login divider
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

                // Google sign-in
                if (context.read<AuthService>().canSignInWithGoogle)
                  OutlinedButton.icon(
                    onPressed: _loading ? null : _signInWithGoogle,
                    icon: const Icon(Icons.g_mobiledata, size: 24),
                    label: const Text('Continue with Google'),
                  ),
                if (context.read<AuthService>().canSignInWithGoogle)
                  const SizedBox(height: 12),

                // Apple sign-in
                if (context.read<AuthService>().canSignInWithApple)
                  OutlinedButton.icon(
                    onPressed: _loading ? null : _signInWithApple,
                    icon: const Icon(Icons.apple, size: 24),
                    label: const Text('Continue with Apple'),
                  ),

                const SizedBox(height: 24),

                // Sign In link
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const AuthScreen(),
                      ),
                    );
                  },
                  child: const Text('Already have an account? Sign In'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Select your birthday',
    );
    if (picked != null) {
      setState(() {
        _birthday = picked;
        _birthdayCtrl.text =
            '${picked.month}/${picked.day}/${picked.year}';
      });
    }
  }

  int _calculateAge(DateTime birthday) {
    final now = DateTime.now();
    int age = now.year - birthday.year;
    if (now.month < birthday.month ||
        (now.month == birthday.month && now.day < birthday.day)) {
      age--;
    }
    return age;
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthService>();
      final cred = await auth.signUpWithEmail(
        _emailCtrl.text.trim(),
        _passwordCtrl.text,
      );
      if (cred?.user != null) {
        final effectiveGender =
            _gender == 'Other' ? _genderOtherCtrl.text.trim() : _gender;

        await auth.getOrCreateUser(
          cred!.user!,
          displayName: _nameCtrl.text.trim(),
          birthday: _birthday,
          gender: effectiveGender,
          neighborhood: _neighborhoodCtrl.text.trim().isNotEmpty
              ? _neighborhoodCtrl.text.trim()
              : null,
          bio: _bioCtrl.text.trim().isNotEmpty ? _bioCtrl.text.trim() : null,
        );
        final analytics = context.read<AnalyticsService>();
        analytics.logSignUp(method: 'email');
        analytics.setUserProperties(userId: cred.user!.uid);
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (r) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => _error = _friendlyAuthError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _socialSignIn(Future<UserCredential?> Function() signIn, String method) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthService>();
      final cred = await signIn();
      if (cred?.user != null) {
        final user = await auth.getOrCreateUser(cred!.user!);
        if (!mounted) return;
        final analytics = context.read<AnalyticsService>();
        analytics.logSignUp(method: method);
        analytics.setUserProperties(userId: cred.user!.uid);

        // If profile is incomplete (social sign-up), send to profile completion
        if (user != null && !auth.isProfileComplete(user)) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => CompleteProfileScreen(
                uid: cred.user!.uid,
                prefillName: cred.user!.displayName,
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
