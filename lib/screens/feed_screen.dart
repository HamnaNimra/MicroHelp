import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/post_model.dart';
import '../services/firestore_service.dart';
import '../widgets/error_view.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/loading_view.dart';
import 'post_detail_screen.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = context.watch<FirestoreService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Feed')),
      body: StreamBuilder(
        stream: firestore.getActivePosts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView(message: 'Loading posts...');
          }
          if (snapshot.hasError) {
            return ErrorView(
              message: 'Could not load posts. Check your connection and try again.',
              onRetry: () => (context as Element).markNeedsBuild(),
            );
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const EmptyStateView(
              icon: Icons.post_add,
              title: 'No active posts',
              subtitle: 'Be the first to post! Tap the Post tab below.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final doc = docs[i];
              final post = PostModel.fromFirestore(doc);
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  title: Text(
                    post.type == PostType.request ? 'Request' : 'Offer',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: post.type == PostType.request
                          ? Colors.orange
                          : Colors.green,
                    ),
                  ),
                  subtitle: Text(
                    post.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: post.estimatedMinutes != null
                      ? Text('~${post.estimatedMinutes} min')
                      : null,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PostDetailScreen(postId: post.id),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
