import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import '../services/firestore_service.dart';

class TaskCompletionScreen extends StatelessWidget {
  const TaskCompletionScreen({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Complete task')),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: firestore.getPost(postId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final doc = snapshot.data!;
          if (!doc.exists || doc.data() == null) {
            return const Center(child: Text('Post not found'));
          }
          final post = PostModel.fromFirestore(doc);

          final isHelper = post.acceptedBy == uid;
          final isOwner = post.userId == uid;
          final canComplete = (isHelper || isOwner) && !post.completed;

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  post.description,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 24),
                if (post.completed)
                  const Chip(
                    label: Text('Already completed'),
                    backgroundColor: Colors.grey,
                  )
                else if (canComplete)
                  FilledButton(
                    onPressed: () async {
                      await firestore.completePost(postId);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Task marked complete. Trust score will be updated.')),
                        );
                      }
                    },
                    child: const Text('Mark as completed'),
                  )
                else
                  const Text('Only the helper or poster can mark this complete.'),
              ],
            ),
          );
        },
      ),
    );
  }
}
