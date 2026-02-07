import 'package:flutter/material.dart';
import '../models/message_model.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.initial,
    this.profilePicUrl,
    this.senderName,
  });

  final MessageModel message;
  final bool isMe;

  /// Always shown — the first letter of the sender's real name.
  final String initial;

  /// If the sender has shared their photo, their profile pic URL.
  final String? profilePicUrl;

  /// If the sender has shared their name, their display name.
  final String? senderName;

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: 16,
      backgroundImage:
          profilePicUrl != null ? NetworkImage(profilePicUrl!) : null,
      child: profilePicUrl == null
          ? Text(
              initial,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            )
          : null,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            avatar,
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (senderName != null && !isMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        senderName!,
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                      ),
                    ),
                  Text(message.text),
                  Text(
                    '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            avatar,
          ],
        ],
      ),
    );
  }
}
