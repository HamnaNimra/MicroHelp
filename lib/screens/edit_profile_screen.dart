import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'landing_screen.dart';

// Gender and birthday are set at sign-up and cannot be changed.

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.user});

  final UserModel user;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _neighborhoodCtrl;
  late final TextEditingController _bioCtrl;
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _neighborhoodCtrl = TextEditingController(text: widget.user.neighborhood);
    _bioCtrl = TextEditingController(text: widget.user.bio);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _neighborhoodCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final effectiveGender =
          _gender == 'Other' ? _genderOtherCtrl.text.trim() : _gender;

      final updates = <String, dynamic>{
        'name': _nameController.text.trim(),
        'lastActive': FieldValue.serverTimestamp(),
      };
      if (effectiveGender != null) updates['gender'] = effectiveGender;
      if (_ageRange != null) updates['ageRange'] = _ageRange;
      if (_neighborhoodCtrl.text.trim().isNotEmpty) {
        updates['neighborhood'] = _neighborhoodCtrl.text.trim();
      }
      if (_bioCtrl.text.trim().isNotEmpty) {
        updates['bio'] = _bioCtrl.text.trim();
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.id)
          .update(updates);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save. Check your connection and try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showDeleteAccountDialog() {
    final auth = context.read<AuthService>();
    final provider = auth.getSignInProvider();
    final isPasswordUser = provider == 'password';

    final passwordCtrl = TextEditingController();
    bool deleting = false;
    String? error;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Delete account?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This will permanently delete your account and all your data. '
                'This action cannot be undone.',
              ),
              if (isPasswordUser) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: passwordCtrl,
                  obscureText: true,
                  enabled: !deleting,
                  decoration: InputDecoration(
                    labelText: 'Enter your password to confirm',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outlined),
                    errorText: error,
                  ),
                ),
              ] else ...[
                const SizedBox(height: 16),
                Text(
                  provider == 'google.com'
                      ? 'You will be asked to sign in with Google to confirm.'
                      : 'You will be asked to sign in with Apple to confirm.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: deleting ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: deleting
                  ? null
                  : () async {
                      if (isPasswordUser && passwordCtrl.text.isEmpty) {
                        setDialogState(() => error = 'Enter your password');
                        return;
                      }
                      setDialogState(() {
                        deleting = true;
                        error = null;
                      });
                      try {
                        if (isPasswordUser) {
                          await auth.deleteAccount(passwordCtrl.text);
                        } else {
                          await auth.deleteAccountWithProvider();
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (_) => const LandingScreen()),
                            (r) => false,
                          );
                        }
                      } on FirebaseAuthException catch (e) {
                        setDialogState(() {
                          deleting = false;
                          switch (e.code) {
                            case 'wrong-password':
                            case 'invalid-credential':
                              error = 'Incorrect password. Please try again.';
                            case 'too-many-requests':
                              error = 'Too many attempts. Try again later.';
                            default:
                              error = e.message ?? 'Failed to delete account.';
                          }
                        });
                      } catch (_) {
                        setDialogState(() {
                          deleting = false;
                          error = 'Something went wrong. Please try again.';
                        });
                      }
                    },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: deleting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(isPasswordUser
                      ? 'Delete permanently'
                      : 'Continue with ${provider == 'google.com' ? 'Google' : 'Apple'}'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Display name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(),
                ),
                items: _genderOptions
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => setState(() => _gender = v),
              ),
              if (_gender == 'Other') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _genderOtherCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Please specify',
                    border: OutlineInputBorder(),
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
              DropdownButtonFormField<String>(
                initialValue: _ageRange,
                decoration: const InputDecoration(
                  labelText: 'Age range',
                  border: OutlineInputBorder(),
                ),
                items: _ageRangeOptions
                    .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                    .toList(),
                onChanged: (v) => setState(() => _ageRange = v),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _neighborhoodCtrl,
                decoration: const InputDecoration(
                  labelText: 'Neighborhood or postal code',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioCtrl,
                maxLines: 3,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: 'Short bio',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _showDeleteAccountDialog,
                icon: const Icon(Icons.delete_forever),
                label: const Text('Delete account'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
