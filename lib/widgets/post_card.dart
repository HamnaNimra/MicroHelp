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

  String _timeLeft() {
    final diff = post.expiresAt.difference(DateTime.now());
    if (diff.isNegative) return 'Expired';
    if (diff.inDays > 0) return '${diff.inDays}d left';
    if (diff.inHours > 0) return '${diff.inHours}h left';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m left';
    return 'Soon';
  }

  Color _timeLeftColor(BuildContext context) {
    final diff = post.expiresAt.difference(DateTime.now());
    if (diff.inHours < 2) return Theme.of(context).colorScheme.error;
    if (diff.inHours < 6) return AppColors.pending(context);
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isRequest = post.type == PostType.request;
    final accentColor =
        isRequest ? AppColors.request(context) : AppColors.offer(context);
    final hasHelper = post.acceptedBy != null;

    return TapScale(
      onTap: onTap,
      child: Card(
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
                      // Top row: type pill + badges + time left
                      Row(
                        children: [
                          _TypePill(isRequest: isRequest, color: accentColor),
                          if (isOwn) ...[
                            const SizedBox(width: 8),
                            _SmallBadge(
                              icon: Icons.person,
                              label: 'Yours',
                              bgColor: cs.primaryContainer,
                              fgColor: cs.primary,
                            ),
                          ],
                          if (hasHelper && !isOwn) ...[
                            const SizedBox(width: 8),
                            _SmallBadge(
                              icon: Icons.handshake,
                              label: 'In progress',
                              bgColor: cs.tertiaryContainer,
                              fgColor: cs.tertiary,
                            ),
                          ],
                          if (post.global) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.public, size: 14, color: cs.onSurfaceVariant),
                          ],
                          const Spacer(),
                          // Time left indicator
                          Text(
                            _timeLeft(),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: _timeLeftColor(context),
                                  fontWeight: FontWeight.w600,
                                ),
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
                      const SizedBox(height: 10),
                      // Bottom row: poster info + estimated time + distance
                      Row(
                        children: [
                          if (post.posterGender != null ||
                              post.posterAgeRange != null)
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(Icons.person_outline, size: 14, color: cs.onSurfaceVariant),
                                  const SizedBox(width: 3),
                                  Flexible(
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
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            const Spacer(),
                          if (post.estimatedMinutes != null) ...[
                            const SizedBox(width: 12),
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
                          if (distanceKm != null) ...[
                            const SizedBox(width: 12),
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
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Right arrow indicator
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: cs.onSurfaceVariant.withAlpha(120),
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isRequest ? Icons.help_outline : Icons.volunteer_activism,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            isRequest ? 'Request' : 'Offer',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  const _SmallBadge({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.fgColor,
  });

  final IconData icon;
  final String label;
  final Color bgColor;
  final Color fgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fgColor),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fgColor,
            ),
          ),
        ],
      ),
    );
  }
}
