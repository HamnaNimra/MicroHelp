import 'package:flutter/material.dart';
import '../models/post_model.dart';

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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        title: Row(
          children: [
            Text(
              post.type == PostType.request ? 'Request' : 'Offer',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color:
                    post.type == PostType.request ? Colors.orange : Colors.green,
              ),
            ),
            if (isOwn) ...[
              const SizedBox(width: 8),
              Icon(Icons.person,
                  size: 16, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 2),
              Text(
                'Your post',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (distanceKm != null)
              Text(
                distanceKm! < 1
                    ? '${(distanceKm! * 1000).toStringAsFixed(0)} m away'
                    : '${distanceKm!.toStringAsFixed(1)} km away',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
          ],
        ),
        trailing: post.estimatedMinutes != null
            ? Text('~${post.estimatedMinutes} min')
            : null,
        onTap: onTap,
      ),
    );
  }
}
