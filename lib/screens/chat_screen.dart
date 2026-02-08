import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/analytics_service.dart';
import '../widgets/error_view.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/message_bubble.dart';
import 'task_completion_screen.dart';
import 'report_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.postId});

  final String postId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  String? _otherUserId;
  bool _participantsLoaded = false;

  // User data for both participants
  UserModel? _myUser;
  UserModel? _otherUser;

  @override
  void initState() {
    super.initState();
    _loadParticipants();
  }

  Future<void> _loadParticipants() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final firestore = context.read<FirestoreService>();
      final doc = await firestore.getPost(widget.postId);
      final data = doc.data();
      if (data == null) return;
      final postOwner = data['userId'] as String?;
      final acceptedBy = data['acceptedBy'] as String?;
      final otherId = (postOwner == uid) ? acceptedBy : postOwner;

      if (otherId == null) {
        if (mounted) setState(() => _participantsLoaded = true);
        return;
      }

      // Set otherUserId immediately so streams can start
      if (mounted) setState(() => _otherUserId = otherId);

      // Fetch both users in parallel
      final results = await Future.wait([
        firestore.getUser(uid),
        firestore.getUser(otherId),
      ]);

      if (mounted) {
        setState(() {
          _participantsLoaded = true;
          if (results[0].exists) _myUser = UserModel.fromFirestore(results[0]);
          if (results[1].exists) {
            _otherUser = UserModel.fromFirestore(results[1]);
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _participantsLoaded = true);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final message = MessageModel(
      id: '',
      senderId: uid,
      text: text,
      timestamp: DateTime.now(),
    );
    try {
      final firestore = context.read<FirestoreService>();
      final analytics = context.read<AnalyticsService>();
      await firestore.sendMessage(widget.postId, message);
      analytics.logMessageSent();
      _textController.clear();
      _scrollToBottom();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to send message.'),
            action: SnackBarAction(label: 'Retry', onPressed: _send),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      // Use addPostFrameCallback so the list has time to lay out
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _blockUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _otherUserId == null) return;

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
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Block'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await context.read<FirestoreService>().blockUser(uid, _otherUserId!);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('User blocked.'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to block user. Try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showSharingSettings() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final firestore = context.read<FirestoreService>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        expand: false,
        builder: (ctx, scrollController) =>
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: firestore.getChatSharing(widget.postId, uid),
          builder: (ctx, snapshot) {
            final data = snapshot.data?.data() ?? {};
            final shareName = data['shareName'] as bool? ?? false;
            final sharePhone = data['sharePhone'] as bool? ?? false;
            final sharePhoto = data['sharePhoto'] as bool? ?? false;
            final shareLocation = data['shareLocation'] as bool? ?? false;

            final hasPhone =
                _myUser?.phone != null && _myUser!.phone!.isNotEmpty;
            final hasPhoto = _myUser?.profilePic != null;

            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Sharing preferences',
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose what the other person can see in this chat. '
                  'Once you share your name, phone, or photo it cannot be un-shared.',
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Share your name'),
                  subtitle: Text(shareName
                      ? 'Your name is visible (cannot be undone)'
                      : 'Show your display name'),
                  value: shareName,
                  onChanged: shareName
                      ? null
                      : (v) {
                          if (v) {
                            firestore.updateChatSharing(
                              widget.postId,
                              uid,
                              shareName: true,
                            );
                          }
                        },
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  title: const Text('Share your phone'),
                  subtitle: Text(!hasPhone
                      ? 'Add a phone number in Edit Profile first'
                      : sharePhone
                          ? 'Your phone is visible (cannot be undone)'
                          : 'Show your phone number'),
                  value: sharePhone,
                  onChanged: (sharePhone || !hasPhone)
                      ? null
                      : (v) {
                          if (v) {
                            firestore.updateChatSharing(
                              widget.postId,
                              uid,
                              sharePhone: true,
                            );
                          }
                        },
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  title: const Text('Share your photo'),
                  subtitle: Text(!hasPhoto
                      ? 'Add a profile picture in Edit Profile first'
                      : sharePhoto
                          ? 'Your photo is visible (cannot be undone)'
                          : 'Show your profile picture'),
                  value: sharePhoto,
                  onChanged: (sharePhoto || !hasPhoto)
                      ? null
                      : (v) {
                          if (v) {
                            firestore.updateChatSharing(
                              widget.postId,
                              uid,
                              sharePhoto: true,
                            );
                          }
                        },
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  title: const Text('Share your location'),
                  subtitle: Text(shareLocation
                      ? 'Your approximate location is visible'
                      : 'Show your approximate location'),
                  value: shareLocation,
                  onChanged: (v) {
                    firestore.updateChatSharing(
                      widget.postId,
                      uid,
                      shareLocation: v,
                    );
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Returns the display name or "Anonymous" based on sharing prefs.
  String _displayName(UserModel? user, Map<String, dynamic> sharing) {
    final shared = sharing['shareName'] as bool? ?? false;
    if (shared && user != null) return user.name;
    return 'Anonymous';
  }

  @override
  Widget build(BuildContext context) {
    final firestore = context.watch<FirestoreService>();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: _otherUserId == null
            ? const Text('Chat')
            : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: firestore.getChatSharing(
                    widget.postId, _otherUserId!),
                builder: (context, snapshot) {
                  final data = snapshot.data?.data() ?? {};
                  final name = _displayName(_otherUser, data);
                  return Text(name);
                },
              ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Sharing settings',
            onPressed: _showSharingSettings,
          ),
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TaskCompletionScreen(postId: widget.postId),
              ),
            ),
          ),
          if (_otherUserId != null)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'report') {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ReportScreen(
                        reportedUserId: _otherUserId!,
                      ),
                    ),
                  );
                } else if (value == 'block') {
                  _blockUser();
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'report',
                  child: ListTile(
                    leading: Icon(Icons.flag,
                        color: Theme.of(ctx).colorScheme.tertiary),
                    title: const Text('Report user'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'block',
                  child: ListTile(
                    leading: Icon(Icons.block,
                        color: Theme.of(ctx).colorScheme.error),
                    title: const Text('Block user'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
        ],
      ),
      body: uid == null
          ? const SizedBox.shrink()
          : _ChatBody(
              postId: widget.postId,
              uid: uid,
              otherUserId: _otherUserId,
              myUser: _myUser,
              otherUser: _otherUser,
              participantsLoaded: _participantsLoaded,
              textController: _textController,
              scrollController: _scrollController,
              onSend: _send,
              onScrollToBottom: _scrollToBottom,
              firestore: firestore,
            ),
    );
  }
}

/// The body of the chat — shows messages immediately, loads user info in parallel.
class _ChatBody extends StatelessWidget {
  const _ChatBody({
    required this.postId,
    required this.uid,
    required this.otherUserId,
    required this.myUser,
    required this.otherUser,
    required this.participantsLoaded,
    required this.textController,
    required this.scrollController,
    required this.onSend,
    required this.onScrollToBottom,
    required this.firestore,
  });

  final String postId;
  final String uid;
  final String? otherUserId;
  final UserModel? myUser;
  final UserModel? otherUser;
  final bool participantsLoaded;
  final TextEditingController textController;
  final ScrollController scrollController;
  final VoidCallback onSend;
  final VoidCallback onScrollToBottom;
  final FirestoreService firestore;

  String _initial(UserModel? user) {
    if (user != null && user.name.isNotEmpty) {
      return user.name[0].toUpperCase();
    }
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    // If we know both user IDs, listen to sharing prefs.
    // Otherwise, show messages without sharing data.
    if (otherUserId == null) {
      // Still resolving participants — show messages anyway
      return _buildMessagesColumn(context, {}, {});
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: firestore.getChatSharing(postId, uid),
      builder: (context, myShareSnap) {
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: firestore.getChatSharing(postId, otherUserId!),
          builder: (context, otherShareSnap) {
            final mySharing = myShareSnap.data?.data() ?? {};
            final otherSharing = otherShareSnap.data?.data() ?? {};
            return _buildMessagesColumn(context, mySharing, otherSharing);
          },
        );
      },
    );
  }

  Widget _buildMessagesColumn(
    BuildContext context,
    Map<String, dynamic> mySharing,
    Map<String, dynamic> otherSharing,
  ) {
    final otherSharesName = otherSharing['shareName'] as bool? ?? false;
    final otherSharesPhoto = otherSharing['sharePhoto'] as bool? ?? false;
    final otherSharesPhone = otherSharing['sharePhone'] as bool? ?? false;
    final otherSharesLocation =
        otherSharing['shareLocation'] as bool? ?? false;

    return Column(
      children: [
        _SharedInfoBar(
          otherUser: otherUser,
          otherSharesName: otherSharesName,
          otherSharesPhone: otherSharesPhone,
          otherSharesLocation: otherSharesLocation,
        ),
        Expanded(
          child: StreamBuilder(
            stream: firestore.getMessages(postId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const ErrorView(
                  message:
                      'Could not load messages. Check your connection.',
                );
              }
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              final docs = snapshot.data!.docs;
              final messages = docs
                  .map((d) => MessageModel.fromFirestore(d))
                  .toList();

              if (messages.isEmpty) {
                return const EmptyStateView(
                  icon: Icons.chat_bubble_outline,
                  title: 'No messages yet',
                  subtitle: 'Say hello!',
                );
              }

              // Auto-scroll to bottom when new messages arrive
              onScrollToBottom();

              return ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, i) {
                  final msg = messages[i];
                  // System messages
                  if (msg.senderId == 'system') {
                    return Center(
                      child: Container(
                        margin:
                            const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          msg.text,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer,
                              ),
                        ),
                      ),
                    );
                  }

                  final isMe = msg.senderId == uid;
                  final senderUser = isMe ? myUser : otherUser;
                  final senderSharing =
                      isMe ? mySharing : otherSharing;
                  final sharesPhoto = isMe
                      ? (mySharing['sharePhoto'] as bool? ?? false)
                      : otherSharesPhoto;

                  return MessageBubble(
                    message: msg,
                    isMe: isMe,
                    initial: _initial(senderUser),
                    profilePicUrl: sharesPhoto
                        ? senderUser?.profilePic
                        : null,
                    senderName: (senderSharing['shareName']
                                as bool? ??
                            false)
                        ? senderUser?.name
                        : null,
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: textController,
                  decoration: const InputDecoration(
                    hintText: 'Message',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => onSend(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: onSend,
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A compact info bar showing what the other user has shared (phone, location).
class _SharedInfoBar extends StatelessWidget {
  const _SharedInfoBar({
    required this.otherUser,
    required this.otherSharesName,
    required this.otherSharesPhone,
    required this.otherSharesLocation,
  });

  final UserModel? otherUser;
  final bool otherSharesName;
  final bool otherSharesPhone;
  final bool otherSharesLocation;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    if (otherSharesPhone &&
        otherUser?.phone != null &&
        otherUser!.phone!.isNotEmpty) {
      chips.add(Chip(
        avatar: const Icon(Icons.phone, size: 16),
        label: Text(otherUser!.phone!),
        visualDensity: VisualDensity.compact,
      ));
    }

    if (otherSharesLocation &&
        otherUser?.neighborhood != null &&
        otherUser!.neighborhood!.isNotEmpty) {
      chips.add(Chip(
        avatar: const Icon(Icons.location_on, size: 16),
        label: Text(otherUser!.neighborhood!),
        visualDensity: VisualDensity.compact,
      ));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Wrap(
        spacing: 8,
        children: chips,
      ),
    );
  }
}
