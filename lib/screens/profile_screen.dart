import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../theme/theme_provider.dart';
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
  const ProfileScreen({super.key, this.onNavigateToCreatePost});

  final VoidCallback? onNavigateToCreatePost;

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
          final cs = Theme.of(context).colorScheme;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                // Profile header card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        ProfileAvatar(
                          name: user.name,
                          profilePicUrl: user.profilePic,
                          isVerified: user.idVerified,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user.name,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        TrustScoreBadge(score: user.trustScore),
                        if (user.bio != null && user.bio!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            user.bio!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 16),
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
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Actions card
                Card(
                  child: Column(
                    children: [
                      _ProfileTile(
                        icon: Icons.edit,
                        title: 'Edit profile',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EditProfileScreen(user: user),
                          ),
                        ),
                      ),
                      const Divider(height: 1, indent: 56),
                      _ProfileTile(
                        icon: Icons.post_add,
                        title: 'My Posts',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => MyPostsScreen(
                              onNavigateToCreatePost: onNavigateToCreatePost != null
                                  ? () {
                                      Navigator.of(context).pop();
                                      onNavigateToCreatePost!();
                                    }
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      const Divider(height: 1, indent: 56),
                      _ProfileTile(
                        icon: Icons.emoji_events,
                        title: 'Badges & gamification',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BadgesScreen(userId: uid),
                          ),
                        ),
                      ),
                      const Divider(height: 1, indent: 56),
                      if (!user.idVerified)
                        _ProfileTile(
                          icon: Icons.verified_user,
                          title: 'Verify identity',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const VerifyIdentityScreen(),
                            ),
                          ),
                        )
                      else
                        ListTile(
                          leading: Icon(Icons.verified, color: cs.primary),
                          title: const Text('Identity verified'),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        ),
                      const Divider(height: 1, indent: 56),
                      _ProfileTile(
                        icon: Icons.play_circle_outline,
                        title: 'View tutorial',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const OnboardingScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Appearance card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Appearance',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Consumer<ThemeProvider>(
                          builder: (context, themeProvider, _) {
                            return SegmentedButton<ThemeSetting>(
                              segments: const [
                                ButtonSegment(
                                  value: ThemeSetting.light,
                                  icon: Icon(Icons.light_mode, size: 18),
                                  label: Text('Light'),
                                ),
                                ButtonSegment(
                                  value: ThemeSetting.system,
                                  icon: Icon(Icons.settings_brightness, size: 18),
                                  label: Text('System'),
                                ),
                                ButtonSegment(
                                  value: ThemeSetting.dark,
                                  icon: Icon(Icons.dark_mode, size: 18),
                                  label: Text('Dark'),
                                ),
                              ],
                              selected: {themeProvider.setting},
                              onSelectionChanged: (s) =>
                                  themeProvider.setSetting(s.first),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Danger zone
                Card(
                  child: ListTile(
                    leading: Icon(Icons.delete_forever, color: cs.error),
                    title: Text(
                      'Delete account',
                      style: TextStyle(color: cs.error),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    onTap: () => _showDeleteAccountDialog(context),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: onTap,
    );
  }
}
