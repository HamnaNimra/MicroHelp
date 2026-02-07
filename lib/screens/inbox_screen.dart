import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import 'post_detail_screen.dart';
import 'chat_screen.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text('Not signed in'));
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Inbox'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'My Posts'),
              Tab(text: 'Helping'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _MyPostsTab(uid: uid),
            _HelpingTab(uid: uid),
          ],
        ),
      ),
    );
  }
}

/// Shows posts created by the current user with their status.
class _MyPostsTab extends StatelessWidget {
  const _MyPostsTab({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: uid)
          .orderBy('expiresAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const ErrorView(message: 'Could not load your posts.');
        }
        if (!snapshot.hasData) {
          return const LoadingView(message: 'Loading...');
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const EmptyStateView(
            icon: Icons.post_add,
            title: 'No posts yet',
            subtitle: 'Posts you create will appear here.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final post = PostModel.fromFirestore(docs[i]);
            return _InboxTile(
              post: post,
              postId: docs[i].id,
              subtitle: _myPostStatus(post),
              trailing: _statusIcon(post),
            );
          },
        );
      },
    );
  }

  String _myPostStatus(PostModel post) {
    if (post.completed) return 'Completed';
    if (post.acceptedBy != null) return 'Someone accepted — open chat';
    if (post.expiresAt.isBefore(DateTime.now())) return 'Expired';
    return 'Active — waiting for a helper';
  }

  Widget _statusIcon(PostModel post) {
    if (post.completed) {
      return const Icon(Icons.check_circle, color: Colors.green, size: 20);
    }
    if (post.acceptedBy != null) {
      return const Icon(Icons.chat_bubble, color: Colors.blue, size: 20);
    }
    if (post.expiresAt.isBefore(DateTime.now())) {
      return const Icon(Icons.schedule, color: Colors.grey, size: 20);
    }
    return const Icon(Icons.hourglass_top, color: Colors.orange, size: 20);
  }
}

/// Shows posts the current user has accepted to help with.
class _HelpingTab extends StatelessWidget {
  const _HelpingTab({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('acceptedBy', isEqualTo: uid)
          .orderBy('expiresAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const ErrorView(message: 'Could not load your tasks.');
        }
        if (!snapshot.hasData) {
          return const LoadingView(message: 'Loading...');
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const EmptyStateView(
            icon: Icons.volunteer_activism,
            title: 'Not helping anyone yet',
            subtitle: 'Posts you accept will appear here.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final post = PostModel.fromFirestore(docs[i]);
            return _InboxTile(
              post: post,
              postId: docs[i].id,
              subtitle: post.completed ? 'Completed' : 'In progress — open chat',
              trailing: post.completed
                  ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                  : const Icon(Icons.chat_bubble, color: Colors.blue, size: 20),
            );
          },
        );
      },
    );
  }
}

class _InboxTile extends StatelessWidget {
  const _InboxTile({
    required this.post,
    required this.postId,
    required this.subtitle,
    required this.trailing,
  });

  final PostModel post;
  final String postId;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        title: Text(
          post.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: trailing,
        onTap: () {
          // If there's an active chat, go there; otherwise go to detail
          if (post.acceptedBy != null && !post.completed) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChatScreen(postId: postId),
              ),
            );
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PostDetailScreen(postId: postId),
              ),
            );
          }
        },
      ),
    );
  }
}
