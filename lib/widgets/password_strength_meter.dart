import 'package:flutter/material.dart';

enum PasswordStrength { weak, medium, strong }

class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    final strength = _evaluate(password);
    final Color color;
    final String label;
    final double fraction;

    switch (strength) {
      case PasswordStrength.weak:
        color = Colors.red;
        label = 'Weak';
        fraction = 0.33;
      case PasswordStrength.medium:
        color = Colors.orange;
        label = 'Medium';
        fraction = 0.66;
      case PasswordStrength.strong:
        color = Colors.green;
        label = 'Strong';
        fraction = 1.0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            color: color,
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
        ),
      ],
    );
  }

  static PasswordStrength _evaluate(String password) {
    int score = 0;
    if (password.length >= 6) score++;
    if (password.length >= 10) score++;
    if (RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#\$%\^&\*\(\)_\+\-=\[\]\{\};:,.<>?/\\|`~]')
        .hasMatch(password)) score++;

    if (score <= 1) return PasswordStrength.weak;
    if (score <= 3) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }
}
