import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/post_model.dart';
import '../services/firestore_service.dart';
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
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text('No active posts. Be the first to post!'),
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
