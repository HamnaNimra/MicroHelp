import 'package:flutter/material.dart';
import 'animated_count.dart';

class TrustScoreBadge extends StatelessWidget {
  const TrustScoreBadge({
    super.key,
    required this.score,
    this.size = TrustScoreBadgeSize.small,
  });

  final int score;
  final TrustScoreBadgeSize size;

  @override
  Widget build(BuildContext context) {
    if (size == TrustScoreBadgeSize.large) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.verified_user,
                  size: 48, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(
                'Trust score',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              AnimatedCount(
                value: score,
                style: Theme.of(context).textTheme.headlineMedium,
                duration: const Duration(milliseconds: 1000),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.verified_user,
            size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        AnimatedCount(
          value: score,
          prefix: 'Trust score: ',
          style: Theme.of(context).textTheme.titleMedium,
          duration: const Duration(milliseconds: 800),
        ),
      ],
    );
  }
}

enum TrustScoreBadgeSize { small, large }
