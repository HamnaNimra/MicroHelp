import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import '../services/firestore_service.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/post_type_chip.dart';
import 'chat_screen.dart';

class PostDetailScreen extends StatelessWidget {
  const PostDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Post detail')),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: firestore.getPost(postId),
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
                      await firestore.acceptPost(postId, uid);
                      if (context.mounted) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(postId: postId),
                          ),
                        );
                      }
                    },
                    child: const Text('Accept'),
                  ),
                if (isHelper || isOwner) ...[
                  if (!post.completed)
                    FilledButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(postId: postId),
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
