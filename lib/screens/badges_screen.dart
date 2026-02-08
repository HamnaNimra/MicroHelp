import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/badges.dart';
import '../theme/app_theme.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/staggered_list_item.dart';
import '../widgets/trust_score_badge.dart';

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
              final earnedIds =
                  badgeSnapshot.data?.docs.map((d) => d.id).toSet() ?? {};
              final earnedDocs = {
                for (final d in badgeSnapshot.data?.docs ?? []) d.id: d.data()
              };

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TrustScoreBadge(
                      score: trustScore,
                      size: TrustScoreBadgeSize.large,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Badges',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    for (var i = 0; i < availableBadges.length; i++)
                      () {
                        final badge = availableBadges[i];
                        final earned = earnedIds.contains(badge.id);
                        final data = earnedDocs[badge.id];
                        final earnedAt = data != null
                            ? (data['earnedAt'] as Timestamp?)?.toDate()
                            : null;

                        // Progress hint for score-based badges
                        String? progress;
                        if (!earned && badge.trustScoreThreshold != null) {
                          final remaining =
                              badge.trustScoreThreshold! - trustScore;
                          if (remaining > 0) {
                            progress = 'Complete $remaining more task${remaining == 1 ? '' : 's'}';
                          }
                        }

                        return StaggeredListItem(
                          index: i,
                          child: Card(
                            color: earned ? null : Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: ListTile(
                              leading: Icon(
                                badge.icon,
                                color: earned
                                    ? AppColors.badgeEarned(context)
                                    : AppColors.badgeUnearned(context),
                                size: 32,
                              ),
                              title: Text(
                                badge.name,
                                style: TextStyle(
                                  color: earned ? null : Theme.of(context).colorScheme.outline,
                                  fontWeight:
                                      earned ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              subtitle: Text(
                                earned
                                    ? badge.description +
                                        (earnedAt != null
                                            ? '\nEarned ${earnedAt.day}/${earnedAt.month}/${earnedAt.year}'
                                            : '')
                                    : progress ?? badge.description,
                                style: TextStyle(
                                  color: earned ? null : Theme.of(context).colorScheme.outline,
                                ),
                              ),
                              trailing: earned
                                  ? Icon(Icons.check_circle,
                                      color: Theme.of(context).colorScheme.primary)
                                  : Icon(Icons.lock_outline,
                                      color: Theme.of(context).colorScheme.outline),
                            ),
                          ),
                        );
                      }(),
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
