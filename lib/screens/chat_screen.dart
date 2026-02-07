import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';
import '../services/firestore_service.dart';
import '../services/analytics_service.dart';
import '../widgets/error_view.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/loading_view.dart';
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

  @override
  void initState() {
    super.initState();
    _loadOtherUser();
  }

  Future<void> _loadOtherUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc =
          await context.read<FirestoreService>().getPost(widget.postId);
      final data = doc.data();
      if (data == null) return;
      final postOwner = data['userId'] as String?;
      final acceptedBy = data['acceptedBy'] as String?;
      if (mounted) {
        setState(() {
          _otherUserId = (postOwner == uid) ? acceptedBy : postOwner;
        });
      }
    } catch (_) {}
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
      await context.read<FirestoreService>().sendMessage(widget.postId, message);
      context.read<AnalyticsService>().logMessageSent();
      _textController.clear();
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to send message.'),
            action: SnackBarAction(label: 'Retry', onPressed: _send),
            backgroundColor: Colors.red,
          ),
        );
      }
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
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
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
    final firestore = context.watch<FirestoreService>();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        actions: [
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
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'report',
                  child: ListTile(
                    leading: Icon(Icons.flag, color: Colors.orange),
                    title: Text('Report user'),
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
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: firestore.getMessages(widget.postId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const ErrorView(
                    message: 'Could not load messages. Check your connection.',
                  );
                }
                if (!snapshot.hasData) {
                  return const LoadingView(message: 'Loading messages...');
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

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final msg = messages[i];
                    return MessageBubble(
                      message: msg,
                      isMe: msg.senderId == uid,
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
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Message',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _send,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
