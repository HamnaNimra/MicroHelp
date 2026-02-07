import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import 'chat_screen.dart';

/// Inbox = conversations (chats). Posts where you're in an active conversation
/// (you're helping, or someone accepted your post).
class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Not signed in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox'),
      ),
      body: _ChatsList(uid: uid),
    );
  }
}

/// Merges "posts I'm helping" and "my posts that have a helper" into one chats list.
class _ChatsList extends StatelessWidget {
  const _ChatsList({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('acceptedBy', isEqualTo: uid)
          .orderBy('expiresAt', descending: true)
          .snapshots(),
      builder: (context, helpingSnapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('posts')
              .where('userId', isEqualTo: uid)
              .orderBy('expiresAt', descending: true)
              .snapshots(),
          builder: (context, myPostsSnapshot) {
            if (helpingSnapshot.hasError || myPostsSnapshot.hasError) {
              return const ErrorView(
                message: 'Could not load conversations.',
              );
            }
            if (!helpingSnapshot.hasData || !myPostsSnapshot.hasData) {
              return const LoadingView(message: 'Loading...');
            }

            final helpingDocs = helpingSnapshot.data!.docs;
            final myPostsDocs = myPostsSnapshot.data!.docs;

            final chatItems = <_ChatItem>[];
            for (final doc in helpingDocs) {
              final post = PostModel.fromFirestore(doc);
              if (!post.completed) {
                chatItems.add(_ChatItem(post: post, postId: doc.id, isHelping: true));
              }
            }
            for (final doc in myPostsDocs) {
              final post = PostModel.fromFirestore(doc);
              if (post.acceptedBy != null && !post.completed) {
                chatItems.add(_ChatItem(post: post, postId: doc.id, isHelping: false));
              }
            }

            if (chatItems.isEmpty) {
              return const EmptyStateView(
                icon: Icons.chat_bubble_outline,
                title: 'No conversations yet',
                subtitle:
                    'When someone accepts your post or you accept someone else\'s, your chats will appear here.',
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: chatItems.length,
              itemBuilder: (context, i) {
                final item = chatItems[i];
                return _ChatTile(
                  post: item.post,
                  postId: item.postId,
                  isHelping: item.isHelping,
                );
              },
            );
          },
        );
      },
    );
  }
}

class _ChatItem {
  final PostModel post;
  final String postId;
  final bool isHelping;
  _ChatItem({required this.post, required this.postId, required this.isHelping});
}

class _ChatTile extends StatelessWidget {
  const _ChatTile({
    required this.post,
    required this.postId,
    required this.isHelping,
  });

  final PostModel post;
  final String postId;
  final bool isHelping;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.chat_bubble, color: Colors.blue, size: 24),
        title: Text(
          post.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          isHelping ? 'You\'re helping' : 'Your post — chat',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChatScreen(postId: postId),
            ),
          );
        },
      ),
    );
  }
}
