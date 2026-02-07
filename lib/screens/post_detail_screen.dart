import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import '../services/firestore_service.dart';
import '../services/analytics_service.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/post_type_chip.dart';
import 'chat_screen.dart';
import 'report_screen.dart';

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  PostModel? _post;

  Future<void> _blockUser(String postOwnerId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Block this user?'),
        content: const Text(
          'Blocked users can\'t contact you and their posts '
          'won\'t appear in your feed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Block'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await context.read<FirestoreService>().blockUser(uid, postOwnerId);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User blocked.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to block user. Try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post detail'),
        actions: [
          if (_post != null && _post!.userId != uid)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'report') {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ReportScreen(
                        reportedUserId: _post!.userId,
                        reportedPostId: widget.postId,
                      ),
                    ),
                  );
                } else if (value == 'block') {
                  _blockUser(_post!.userId);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'report',
                  child: ListTile(
                    leading: Icon(Icons.flag, color: Colors.orange),
                    title: Text('Report post'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'block',
                  child: ListTile(
                    leading: Icon(Icons.block, color: Colors.red),
                    title: Text('Block user'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: firestore.getPost(widget.postId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const ErrorView(
              message: 'Could not load post. Check your connection.',
            );
          }
          if (!snapshot.hasData) {
            return const LoadingView(message: 'Loading post...');
          }
          final doc = snapshot.data!;
          if (!doc.exists || doc.data() == null) {
            return const ErrorView(message: 'Post not found.');
          }
          final post = PostModel.fromFirestore(doc);

          // Update _post so the AppBar actions can access it.
          if (_post == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _post = post);
            });
          }

          final isOwner = post.userId == uid;
          final isHelper = post.acceptedBy == uid;
          final canAccept =
              uid != null && !isOwner && post.acceptedBy == null && !post.completed;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PostTypeChip(type: post.type),
                const SizedBox(height: 16),
                Text(
                  post.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                if (post.estimatedMinutes != null) ...[
                  const SizedBox(height: 8),
                  Text('~${post.estimatedMinutes} min'),
                ],
                const SizedBox(height: 8),
                Text(
                  'Expires: ${post.expiresAt.toIso8601String().substring(0, 16)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  post.anonymous
                      ? 'Anonymous'
                      : 'User: ${post.userId.substring(0, 8)}...',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 24),
                if (canAccept)
                  FilledButton(
                    onPressed: () async {
                      if (uid == null) return;
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Accept this task?'),
                          content: const Text(
                            'You\'re committing to help. The poster will be notified immediately.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Accept'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed != true) return;
                      if (!context.mounted) return;
                      try {
                        await firestore.acceptPost(widget.postId, uid);
                        context.read<AnalyticsService>().logPostAccepted();
                        if (context.mounted) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(postId: widget.postId),
                            ),
                          );
                        }
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to accept. Check your connection and try again.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Accept'),
                  ),
                if (isHelper || isOwner) ...[
                  if (!post.completed)
                    FilledButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(postId: widget.postId),
                        ),
                      ),
                      child: const Text('Open chat'),
                    ),
                  if (post.completed)
                    const Chip(
                        label: Text('Completed', style: TextStyle(color: Colors.white)),
                        backgroundColor: Colors.grey),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
