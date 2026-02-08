import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../widgets/location_autocomplete_field.dart';
import '../widgets/profile_avatar.dart';
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
  late final TextEditingController _phoneCtrl;
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  bool _uploadingPhoto = false;
  String? _profilePicUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _neighborhoodCtrl = TextEditingController(text: widget.user.neighborhood);
    _bioCtrl = TextEditingController(text: widget.user.bio);
    _phoneCtrl = TextEditingController(text: widget.user.phone);
    _profilePicUrl = widget.user.profilePic;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _neighborhoodCtrl.dispose();
    _bioCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Profile picture'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(ctx, ImageSource.camera),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Camera'),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(ctx, ImageSource.gallery),
            icon: const Icon(Icons.photo_library),
            label: const Text('Gallery'),
          ),
        ],
      ),
    );
    if (source == null) return;

    final picked = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (picked == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      final bytes = await picked.readAsBytes();
      final storage = context.read<StorageService>();
      final url = await storage.uploadProfilePicture(
        userId: widget.user.id,
        bytes: bytes,
      );
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.id)
          .update({'profilePic': url});
      if (mounted) setState(() => _profilePicUrl = url);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to upload photo. Try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _deletePhoto() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove profile picture?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _uploadingPhoto = true);
    try {
      final storage = context.read<StorageService>();
      await storage.deleteProfilePicture(widget.user.id);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.id)
          .update({'profilePic': FieldValue.delete()});
      if (mounted) setState(() => _profilePicUrl = null);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to remove photo. Try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final updates = <String, dynamic>{
        'name': _nameController.text.trim(),
        'lastActive': FieldValue.serverTimestamp(),
      };
      if (_neighborhoodCtrl.text.trim().isNotEmpty) {
        updates['neighborhood'] = _neighborhoodCtrl.text.trim();
      }
      if (_bioCtrl.text.trim().isNotEmpty) {
        updates['bio'] = _bioCtrl.text.trim();
      }
      if (_phoneCtrl.text.trim().isNotEmpty) {
        updates['phone'] = _phoneCtrl.text.trim();
      } else {
        updates['phone'] = FieldValue.delete();
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.id)
          .update(updates);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to save. Check your connection and try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _linkProvider(String provider) async {
    try {
      final auth = context.read<AuthService>();
      if (provider == 'google') {
        await auth.linkWithGoogle();
      } else {
        await auth.linkWithApple();
      }
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${provider == 'google' ? 'Google' : 'Apple'} account linked!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        final message = switch (e.code) {
          'credential-already-in-use' => 'This ${provider == 'google' ? 'Google' : 'Apple'} account is already linked to another user.',
          'provider-already-linked' => '${provider == 'google' ? 'Google' : 'Apple'} is already linked to your account.',
          _ => e.message ?? 'Failed to link account.',
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Failed to link account.'), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    }
  }

  Future<void> _unlinkProvider(String providerId) async {
    final providers = context.read<AuthService>().getLinkedProviders();
    if (providers.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('You must keep at least one sign-in method.'),
          backgroundColor: Theme.of(context).colorScheme.tertiary,
        ),
      );
      return;
    }
    try {
      await context.read<AuthService>().unlinkProvider(providerId);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${providerId == 'google.com' ? 'Google' : 'Apple'} account unlinked.'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Failed to unlink account.'), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
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
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.onError,
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
              // Profile picture section
              Center(
                child: Stack(
                  children: [
                    ProfileAvatar(
                      name: _nameController.text.isNotEmpty
                          ? _nameController.text
                          : widget.user.name,
                      profilePicUrl: _profilePicUrl,
                      radius: 56,
                    ),
                    if (_uploadingPhoto)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.scrim.withAlpha(102),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(Icons.camera_alt, color: Theme.of(context).colorScheme.onPrimary, size: 20),
                          onPressed: _uploadingPhoto ? null : _pickAndUploadPhoto,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_profilePicUrl != null) ...[
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: _uploadingPhoto ? null : _deletePhoto,
                    child: const Text('Remove photo'),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Name
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

              // Phone number
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone number (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone_outlined),
                  helperText: 'Only shared if you choose to below',
                ),
              ),
              const SizedBox(height: 16),

              // Gender (read-only)
              TextFormField(
                initialValue: widget.user.gender ?? 'Not set',
                readOnly: true,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(),
                  helperText: 'Set at sign-up and cannot be changed',
                ),
              ),
              const SizedBox(height: 16),

              // Age range (read-only)
              TextFormField(
                initialValue: widget.user.ageRange ?? 'Not set',
                readOnly: true,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Age range',
                  border: OutlineInputBorder(),
                  helperText: 'Set at sign-up and cannot be changed',
                ),
              ),
              const SizedBox(height: 16),

              // Neighborhood
              LocationAutocompleteField(
                controller: _neighborhoodCtrl,
              ),
              const SizedBox(height: 16),

              // Bio
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

              // Linked accounts
              const SizedBox(height: 24),
              Text(
                'Linked accounts',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Link additional sign-in methods to your account.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              _LinkedAccountTile(
                providerName: 'Google',
                providerId: 'google.com',
                icon: Icons.g_mobiledata,
                onLink: () => _linkProvider('google'),
                onUnlink: () => _unlinkProvider('google.com'),
              ),
              _LinkedAccountTile(
                providerName: 'Apple',
                providerId: 'apple.com',
                icon: Icons.apple,
                onLink: () => _linkProvider('apple'),
                onUnlink: () => _unlinkProvider('apple.com'),
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

class _LinkedAccountTile extends StatelessWidget {
  const _LinkedAccountTile({
    required this.providerName,
    required this.providerId,
    required this.icon,
    required this.onLink,
    required this.onUnlink,
  });

  final String providerName;
  final String providerId;
  final IconData icon;
  final VoidCallback onLink;
  final VoidCallback onUnlink;

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final linked = auth.getLinkedProviders().contains(providerId);

    return ListTile(
      leading: Icon(icon, size: 28),
      title: Text(providerName),
      subtitle: Text(linked ? 'Connected' : 'Not connected'),
      contentPadding: EdgeInsets.zero,
      trailing: linked
          ? TextButton(
              onPressed: onUnlink,
              child: const Text('Unlink'),
            )
          : OutlinedButton(
              onPressed: onLink,
              child: const Text('Link'),
            ),
    );
  }
}
