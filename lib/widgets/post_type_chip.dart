import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../theme/app_theme.dart';

class PostTypeChip extends StatelessWidget {
  const PostTypeChip({super.key, required this.type});

  final PostType type;

  @override
  Widget build(BuildContext context) {
    final isRequest = type == PostType.request;
    final color = isRequest ? AppColors.request(context) : AppColors.offer(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Text(
        isRequest ? 'Request' : 'Offer',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
