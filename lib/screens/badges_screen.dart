import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Badges & gamification')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.hasError) {
            return const ErrorView(
              message: 'Could not load badges. Check your connection.',
            );
          }
          if (!userSnapshot.hasData) {
            return const LoadingView(message: 'Loading badges...');
          }
          final trustScore =
              (userSnapshot.data!.data()?['trustScore'] as int?) ?? 0;

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('badges')
                .snapshots(),
            builder: (context, badgeSnapshot) {
              final badges = badgeSnapshot.data?.docs ?? [];

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(Icons.verified_user,
                                size: 48,
                                color: Theme.of(context).colorScheme.primary),
                            const SizedBox(height: 8),
                            Text(
                              'Trust score',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              '$trustScore',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Badges',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    if (badges.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No badges yet. Complete tasks to earn badges!',
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      ...badges.map((doc) {
                        final data = doc.data();
                        final name = data['name'] as String? ?? 'Badge';
                        final desc =
                            data['description'] as String? ?? '';
                        return ListTile(
                          leading: const Icon(Icons.emoji_events),
                          title: Text(name),
                          subtitle:
                              desc.isNotEmpty ? Text(desc) : null,
                        );
                      }),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
