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
import 'chat_screen.dart';

/// Inbox = conversations (chats). Posts where you're in an active conversation
/// (you're helping, or someone accepted your post).
class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key, this.onNavigateToCreatePost, this.onBrowseFeed});

  final VoidCallback? onNavigateToCreatePost;
  final VoidCallback? onBrowseFeed;

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Not signed in')),
      );
    }
    final prefs = context.read<PreferencesService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox'),
      ),
      body: _ChatsList(
        uid: uid,
        showTip: !prefs.hasSeenInboxTip,
        onDismissTip: () {
          prefs.hasSeenInboxTip = true;
          if (mounted) setState(() {});
        },
        onNavigateToCreatePost: widget.onNavigateToCreatePost,
        onBrowseFeed: widget.onBrowseFeed,
      ),
    );
  }
}

/// Merges "posts I'm helping" and "my posts that have a helper" into one chats list.
class _ChatsList extends StatelessWidget {
  const _ChatsList({
    required this.uid,
    required this.showTip,
    required this.onDismissTip,
    this.onNavigateToCreatePost,
    this.onBrowseFeed,
  });
  final String uid;
  final bool showTip;
  final VoidCallback onDismissTip;
  final VoidCallback? onNavigateToCreatePost;
  final VoidCallback? onBrowseFeed;

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
              chatItems.add(_ChatItem(post: post, postId: doc.id, isHelping: true));
            }
            for (final doc in myPostsDocs) {
              final post = PostModel.fromFirestore(doc);
              if (post.acceptedBy != null) {
                chatItems.add(_ChatItem(post: post, postId: doc.id, isHelping: false));
              }
            }
            // Sort: active first, then completed
            chatItems.sort((a, b) {
              if (a.post.completed != b.post.completed) {
                return a.post.completed ? 1 : -1;
              }
              return b.post.expiresAt.compareTo(a.post.expiresAt);
            });

            Widget content;
            if (chatItems.isEmpty) {
              content = EmptyStateView(
                icon: Icons.chat_bubble_outline,
                title: 'No conversations yet',
                subtitle:
                    'When someone accepts your post or you accept someone else\'s, your chats will appear here.',
                primaryActionLabel: onNavigateToCreatePost != null
                    ? 'Create a post'
                    : null,
                onPrimaryAction: onNavigateToCreatePost,
                secondaryActionLabel: onBrowseFeed != null ? 'Browse feed' : null,
                onSecondaryAction: onBrowseFeed,
              );
            } else {
              content = ListView.builder(
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
            }

            if (showTip) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FirstTimeTipBanner(
                    message:
                        'When someone accepts your post or you accept theirs, conversations appear here.',
                    onDismiss: onDismissTip,
                  ),
                  Expanded(child: content),
                ],
              );
            }
            return content;
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
    final IconData leadingIcon;
    final Color leadingColor;
    final String subtitle;

    final cs = Theme.of(context).colorScheme;

    if (post.completed) {
      leadingIcon = Icons.check_circle;
      leadingColor = cs.outline;
      subtitle = isHelping ? 'Completed — you helped' : 'Completed — your post';
    } else if (post.completionRequestedBy != null) {
      leadingIcon = Icons.hourglass_top;
      leadingColor = cs.tertiary;
      subtitle = isHelping ? 'You\'re helping — approval pending' : 'Your post — approval pending';
    } else {
      leadingIcon = Icons.chat_bubble;
      leadingColor = cs.primary;
      subtitle = isHelping ? 'You\'re helping' : 'Your post — chat';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(leadingIcon, color: leadingColor, size: 24),
        title: Text(
          post.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          subtitle,
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
