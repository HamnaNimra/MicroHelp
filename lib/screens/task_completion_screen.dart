import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import '../constants/badges.dart';
import '../services/firestore_service.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';

class TaskCompletionScreen extends StatelessWidget {
  const TaskCompletionScreen({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Complete task')),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: firestore.getPost(postId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const ErrorView(
              message: 'Could not load task. Check your connection.',
            );
          }
          if (!snapshot.hasData) {
            return const LoadingView(message: 'Loading task...');
          }
          final doc = snapshot.data!;
          if (!doc.exists || doc.data() == null) {
            return const ErrorView(message: 'Post not found.');
          }
          final post = PostModel.fromFirestore(doc);

          final isHelper = post.acceptedBy == uid;
          final isOwner = post.userId == uid;
          final canComplete = (isHelper || isOwner) && !post.completed;

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  post.description,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 24),
                if (post.completed)
                  const Chip(
                    label: Text('Already completed'),
                    backgroundColor: Colors.grey,
                  )
                else if (canComplete)
                  FilledButton(
                    onPressed: uid == null
                        ? null
                        : () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Mark as completed?'),
                                content: Text(
                                  isHelper
                                      ? 'Confirm this task is done. You\'ll earn +1 trust score!'
                                      : 'Confirm this task is done. The helper will receive trust score.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Complete'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed != true) return;
                            if (!context.mounted) return;
                            try {
                              await firestore.completePost(postId, uid);
                              // Check for new badges after completion
                              List<BadgeDefinition> newBadges = [];
                              if (isHelper) {
                                newBadges = await firestore.checkAndAwardBadges(uid);
                              }
                              if (context.mounted) {
                                if (newBadges.isNotEmpty) {
                                  await _showBadgeEarnedDialog(context, newBadges);
                                }
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isHelper
                                            ? 'Task completed! You earned +1 trust score.'
                                            : 'Task marked complete!',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              }
                            } catch (_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Failed to complete task. Check your connection and try again.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                    child: const Text('Mark as completed'),
                  )
                else
                  const Text('Only the helper or poster can mark this complete.'),
              ],
            ),
          );
        },
      ),
    );
  }
}
