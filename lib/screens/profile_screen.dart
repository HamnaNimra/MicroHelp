import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/trust_score_badge.dart';
import 'landing_screen.dart';
import 'edit_profile_screen.dart';
import 'badges_screen.dart';
import 'onboarding_screen.dart';
import 'verify_identity_screen.dart';
import 'my_posts_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showDeleteAccountDialog(BuildContext context) {
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
    final auth = context.watch<AuthService>();
    final uid = auth.currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text('Not signed in'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sign out?'),
                  content: const Text('You\'ll need to sign in again to use MicroHelp.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Sign out'),
                    ),
                  ],
                ),
              );
              if (confirmed != true) return;
              await auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LandingScreen()),
                  (r) => false,
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const ErrorView(
              message: 'Could not load profile. Check your connection.',
            );
          }
          if (!snapshot.hasData) {
            return const LoadingView(message: 'Loading profile...');
          }
          final doc = snapshot.data!;
          if (doc.data() == null) {
            return const ErrorView(message: 'Profile not found.');
          }
          final user = UserModel.fromFirestore(doc);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 16),
                ProfileAvatar(
                  name: user.name,
                  profilePicUrl: user.profilePic,
                  isVerified: user.idVerified,
                ),
                const SizedBox(height: 16),
                Text(
                  user.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                TrustScoreBadge(score: user.trustScore),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  alignment: WrapAlignment.center,
                  children: [
                    if (user.gender != null)
                      Chip(
                        avatar: const Icon(Icons.person, size: 18),
                        label: Text(user.gender!),
                      ),
                    if (user.ageRange != null)
                      Chip(
                        avatar: const Icon(Icons.cake, size: 18),
                        label: Text(user.ageRange!),
                      ),
                    if (user.neighborhood != null)
                      Chip(
                        avatar: const Icon(Icons.location_on, size: 18),
                        label: Text(user.neighborhood!),
                      ),
                    if (user.accountAge != null)
                      Chip(
                        avatar: const Icon(Icons.schedule, size: 18),
                        label: Text(user.accountAge!),
                      ),
                  ],
                ),
                if (user.bio != null && user.bio!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    user.bio!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EditProfileScreen(user: user),
                    ),
                  ),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit profile'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const MyPostsScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.post_add),
                  label: const Text('My Posts'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BadgesScreen(userId: uid),
                    ),
                  ),
                  icon: const Icon(Icons.emoji_events),
                  label: const Text('Badges & gamification'),
                ),
                const SizedBox(height: 12),
                if (!user.idVerified)
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const VerifyIdentityScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.verified_user),
                    label: const Text('Verify identity'),
                  )
                else
                  const Chip(
                    avatar: Icon(Icons.verified, color: Colors.blue),
                    label: Text('Identity verified'),
                  ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const OnboardingScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text('View tutorial'),
                ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () => _showDeleteAccountDialog(context),
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Delete account'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
