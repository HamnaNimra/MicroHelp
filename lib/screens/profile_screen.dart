import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
                    if (user.accountAge != null)
                      Chip(
                        avatar: const Icon(Icons.schedule, size: 18),
                        label: Text(user.accountAge!),
                      ),
                  ],
                ),
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
              ],
            ),
          );
        },
      ),
    );
  }
}
