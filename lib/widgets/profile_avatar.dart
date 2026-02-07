import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    this.profilePicUrl,
    this.radius = 48,
  });

  final String name;
  final String? profilePicUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
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
  }
}
