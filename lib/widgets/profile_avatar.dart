import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    this.profilePicUrl,
    this.radius = 48,
    this.isVerified = false,
  });

  final String name;
  final String? profilePicUrl;
  final double radius;
  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: radius,
      backgroundImage:
          profilePicUrl != null ? NetworkImage(profilePicUrl!) : null,
      child: profilePicUrl == null
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: radius >= 48
                  ? Theme.of(context).textTheme.headlineLarge
                  : Theme.of(context).textTheme.titleLarge,
            )
          : null,
    );

    if (!isVerified) return avatar;

    final badgeSize = radius * 0.45;
    return Stack(
      children: [
        avatar,
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.verified,
              size: badgeSize,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}
