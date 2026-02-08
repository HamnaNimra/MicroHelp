import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import '../constants/badges.dart';
import '../services/firestore_service.dart';
import '../services/analytics_service.dart';
import '../widgets/badge_celebration.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';

class TaskCompletionScreen extends StatelessWidget {
  const TaskCompletionScreen({super.key, required this.postId});

  final String postId;

  static Future<void> _showBadgeEarnedDialog(
    BuildContext context,
    List<BadgeDefinition> badges,
  ) {
    return showBadgeCelebration(context, badges);
  }

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
          final canInteract = (isHelper || isOwner) && !post.completed;
          final hasPendingRequest = post.completionRequestedBy != null;
          final requestedByMe = post.completionRequestedBy == uid;
          final requestedByOther = hasPendingRequest && !requestedByMe;

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
                if (post.completed) ...[
                  Chip(
                    label: const Text('Already completed'),
                    backgroundColor: Theme.of(context).colorScheme.outline,
                  ),
                ] else if (!canInteract) ...[
                  const Text('Only the helper or poster can manage completion.'),
                ] else ...[
                  // Show pending request banner
                  if (requestedByMe) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.hourglass_top,
                              color: Theme.of(context).colorScheme.onSecondaryContainer),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'You\'ve requested completion. Waiting for the ${isHelper ? 'requester' : 'helper'} to approve.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (requestedByOther) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'The ${isOwner ? 'helper' : 'requester'} has marked this task as done.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isOwner
                                ? 'Approve to give the helper their trust score.'
                                : 'Approve to confirm the task is complete.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('Approve completion'),
                      onPressed: uid == null
                          ? null
                          : () async {
                              try {
                                await firestore.approveCompletion(postId);
                                if (!context.mounted) return;
                                context.read<AnalyticsService>().logTaskCompleted();
                                // Check badges for the helper
                                if (post.acceptedBy != null) {
                                  try {
                                    final newBadges = await firestore
                                        .checkAndAwardBadges(post.acceptedBy!);
                                    if (context.mounted && newBadges.isNotEmpty) {
                                      final analytics = context.read<AnalyticsService>();
                                      for (final badge in newBadges) {
                                        analytics.logBadgeEarned(badgeId: badge.id);
                                      }
                                      await _showBadgeEarnedDialog(context, newBadges);
                                    }
                                  } catch (_) {
                                    // Badge check is best-effort; don't block completion
                                  }
                                }
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Task completed! Helper earned +1 trust score.'),
                                      backgroundColor: Theme.of(context).colorScheme.primary,
                                    ),
                                  );
                                }
                              } catch (e) {
                                debugPrint('approveCompletion error: $e');
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed: $e'),
                                      backgroundColor: Theme.of(context).colorScheme.error,
                                    ),
                                  );
                                }
                              }
                            },
                    ),
                  ] else ...[
                    // No pending request — show request or direct complete options
                    if (isHelper) ...[
                      // Helper: request completion (requester must approve)
                      FilledButton.icon(
                        icon: const Icon(Icons.done),
                        label: const Text('Mark as done'),
                        onPressed: uid == null
                            ? null
                            : () async {
                                try {
                                  await firestore.requestCompletion(postId, uid);
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                            'Completion request sent! The requester will be asked to approve.'),
                                        backgroundColor: Theme.of(context).colorScheme.primary,
                                      ),
                                    );
                                  }
                                } catch (_) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Failed. Try again.'),
                                        backgroundColor: Theme.of(context).colorScheme.error,
                                      ),
                                    );
                                  }
                                }
                              },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'The requester will be asked to approve.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (isOwner) ...[
                      // Owner: can directly complete
                      FilledButton.icon(
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Mark as completed'),
                        onPressed: uid == null
                            ? null
                            : () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Mark as completed?'),
                                    content: const Text(
                                      'The helper will receive +1 trust score.',
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
                                if (confirmed != true || !context.mounted) return;
                                try {
                                  await firestore.completePost(postId, uid);
                                  if (!context.mounted) return;
                                  context.read<AnalyticsService>().logTaskCompleted();
                                  if (post.acceptedBy != null) {
                                    final newBadges = await firestore
                                        .checkAndAwardBadges(post.acceptedBy!);
                                    if (context.mounted && newBadges.isNotEmpty) {
                                      final analytics = context.read<AnalyticsService>();
                                      for (final badge in newBadges) {
                                        analytics.logBadgeEarned(badgeId: badge.id);
                                      }
                                      await _showBadgeEarnedDialog(context, newBadges);
                                    }
                                  }
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Task marked complete!'),
                                        backgroundColor: Theme.of(context).colorScheme.primary,
                                      ),
                                    );
                                  }
                                } catch (_) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Failed. Try again.'),
                                        backgroundColor: Theme.of(context).colorScheme.error,
                                      ),
                                    );
                                  }
                                }
                              },
                      ),
                    ],
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
