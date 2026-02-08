import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../theme/app_theme.dart';
import 'tap_scale.dart';

class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    this.distanceKm,
    this.onTap,
    this.isOwn = false,
  });

  final PostModel post;
  final double? distanceKm;
  final VoidCallback? onTap;
  final bool isOwn;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isRequest = post.type == PostType.request;
    final accentColor =
        isRequest ? AppColors.request(context) : AppColors.offer(context);

    return TapScale(
      onTap: onTap,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Left accent strip
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: type pill + own badge + time estimate
                      Row(
                        children: [
                          _TypePill(isRequest: isRequest, color: accentColor),
                          if (isOwn) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: cs.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.person,
                                      size: 12, color: cs.primary),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Yours',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: cs.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const Spacer(),
                          if (post.estimatedMinutes != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.schedule,
                                    size: 14, color: cs.onSurfaceVariant),
                                const SizedBox(width: 3),
                                Text(
                                  '~${post.estimatedMinutes} min',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: cs.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Description
                      Text(
                        post.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      // Bottom row: poster info + distance
                      Row(
                        children: [
                          if (post.posterGender != null ||
                              post.posterAgeRange != null)
                            Expanded(
                              child: Text(
                                [
                                  if (post.posterGender != null)
                                    post.posterGender!,
                                  if (post.posterAgeRange != null)
                                    post.posterAgeRange!,
                                ].join(' · '),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                              ),
                            ),
                          if (distanceKm != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.near_me,
                                    size: 14, color: cs.primary),
                                const SizedBox(width: 3),
                                Text(
                                  distanceKm! < 1
                                      ? '${(distanceKm! * 1000).toStringAsFixed(0)} m'
                                      : '${distanceKm!.toStringAsFixed(1)} km',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: cs.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypePill extends StatelessWidget {
  const _TypePill({required this.isRequest, required this.color});

  final bool isRequest;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Text(
        isRequest ? 'Request' : 'Offer',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}
