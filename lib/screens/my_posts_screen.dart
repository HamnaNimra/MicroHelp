import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/post_model.dart';
import '../services/preferences_service.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/error_view.dart';
import '../widgets/first_time_tip_banner.dart';
import '../widgets/loading_view.dart';
import 'post_detail_screen.dart';
import 'chat_screen.dart';

/// Lists posts created by the current user (status, open chat, etc.).
class MyPostsScreen extends StatefulWidget {
  const MyPostsScreen({super.key, this.onNavigateToCreatePost});

  final VoidCallback? onNavigateToCreatePost;

  @override
  State<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
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
        title: const Text('My Posts'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
          final prefs = context.read<PreferencesService>();
          final showTip = !prefs.hasSeenMyPostsTip;

          if (docs.isEmpty) {
            final emptyContent = EmptyStateView(
              icon: Icons.post_add,
              title: 'No posts yet',
              subtitle:
                  'Posts you create will appear here. They show as "Your post" on the feed.',
              primaryActionLabel:
                  widget.onNavigateToCreatePost != null ? 'Create your first post' : null,
              onPrimaryAction: widget.onNavigateToCreatePost,
            );
            if (showTip) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FirstTimeTipBanner(
                    message: 'Your posts show as "Your post" on the feed so you can spot them easily.',
                    onDismiss: () {
                      prefs.hasSeenMyPostsTip = true;
                      if (mounted) setState(() {});
                    },
                  ),
                  Expanded(child: emptyContent),
                ],
              );
            }
            return emptyContent;
          }

          Widget listContent = ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final post = PostModel.fromFirestore(docs[i]);
              return _MyPostTile(
                post: post,
                postId: docs[i].id,
                subtitle: _statusText(post),
                trailing: _statusIcon(post),
              );
            },
          );
          if (showTip) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FirstTimeTipBanner(
                  message: 'Your posts show as "Your post" on the feed so you can spot them easily.',
                  onDismiss: () {
                    prefs.hasSeenMyPostsTip = true;
                    if (mounted) setState(() {});
                  },
                ),
                Expanded(child: listContent),
              ],
            );
          }
          return listContent;
        },
      ),
    );
  }

  static String _statusText(PostModel post) {
    if (post.completed) return 'Completed';
    if (post.acceptedBy != null) return 'Someone accepted — open chat';
    if (post.expiresAt.isBefore(DateTime.now())) return 'Expired';
    return 'Active — waiting for a helper';
  }

  static Widget _statusIcon(PostModel post) {
    return Builder(builder: (context) {
      final cs = Theme.of(context).colorScheme;
      if (post.completed) {
        return Icon(Icons.check_circle, color: cs.outline, size: 20);
      }
      if (post.acceptedBy != null) {
        return Icon(Icons.chat_bubble, color: cs.primary, size: 20);
      }
      if (post.expiresAt.isBefore(DateTime.now())) {
        return Icon(Icons.schedule, color: cs.outline, size: 20);
      }
      return Icon(Icons.hourglass_top, color: cs.tertiary, size: 20);
    });
  }
}

class _MyPostTile extends StatelessWidget {
  const _MyPostTile({
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
