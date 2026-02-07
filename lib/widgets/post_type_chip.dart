import 'package:flutter/material.dart';
import '../models/post_model.dart';

class PostTypeChip extends StatelessWidget {
  const PostTypeChip({super.key, required this.type});

  final PostType type;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        type == PostType.request ? 'Request' : 'Offer',
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor:
          type == PostType.request ? Colors.orange : Colors.green,
    );
  }
}
