import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/profile_avatar.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Blocked users')),
        body: const Center(child: Text('Not signed in')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Blocked users')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data?.data();
          final blockedIds =
              List<String>.from(data?['blockedUsers'] as List? ?? []);

          if (blockedIds.isEmpty) {
            return const EmptyStateView(
              icon: Icons.block,
              title: 'No blocked users',
              subtitle: 'Users you block will appear here.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: blockedIds.length,
            itemBuilder: (context, i) {
              return _BlockedUserTile(
                blockedUserId: blockedIds[i],
                onUnblock: () => _unblock(uid, blockedIds[i]),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _unblock(String currentUserId, String blockedUserId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unblock this user?'),
        content: const Text(
          'They will be able to contact you and their posts '
          'will appear in your feed again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Unblock'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await context
          .read<FirestoreService>()
          .unblockUser(currentUserId, blockedUserId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('User unblocked.'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to unblock. Try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

/// Fetches and displays a blocked user's name + avatar with an unblock button.
class _BlockedUserTile extends StatelessWidget {
  const _BlockedUserTile({
    required this.blockedUserId,
    required this.onUnblock,
  });

  final String blockedUserId;
  final VoidCallback onUnblock;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(blockedUserId)
          .get(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final name = data?['name'] as String? ?? 'Unknown user';
        final profilePic = data?['profilePic'] as String?;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: ProfileAvatar(
              name: name,
              profilePicUrl: profilePic,
              radius: 20,
            ),
            title: Text(name),
            trailing: OutlinedButton(
              onPressed: onUnblock,
              child: const Text('Unblock'),
            ),
          ),
        );
      },
    );
  }
}
