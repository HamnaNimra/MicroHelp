import 'package:flutter/material.dart';
import '../constants/badges.dart';
import '../theme/app_theme.dart';

/// Shows a celebratory dialog when a badge is earned.
/// Features scale-up bounce + golden glow animation.
Future<void> showBadgeCelebration(
  BuildContext context,
  List<BadgeDefinition> badges,
) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Badge celebration',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 500),
    transitionBuilder: (ctx, anim, secondAnim, child) {
      final curve = CurvedAnimation(
        parent: anim,
        curve: Curves.elasticOut,
      );
      return ScaleTransition(
        scale: Tween<double>(begin: 0.5, end: 1.0).animate(curve),
        child: FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: child,
        ),
      );
    },
    pageBuilder: (ctx, anim, secondAnim) {
      return _BadgeCelebrationContent(badges: badges);
    },
  );
}

class _BadgeCelebrationContent extends StatefulWidget {
  const _BadgeCelebrationContent({required this.badges});
  final List<BadgeDefinition> badges;

  @override
  State<_BadgeCelebrationContent> createState() =>
      _BadgeCelebrationContentState();
}

class _BadgeCelebrationContentState extends State<_BadgeCelebrationContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _glow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final badgeColor = AppColors.badgeEarned(context);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withAlpha(50),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Glowing badge icon
              AnimatedBuilder(
                animation: _glow,
                builder: (context, child) {
                  return Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: badgeColor.withAlpha(26),
                      boxShadow: [
                        BoxShadow(
                          color: badgeColor.withAlpha(
                            (80 * _glow.value).round(),
                          ),
                          blurRadius: 24 + (16 * _glow.value),
                          spreadRadius: 2 + (4 * _glow.value),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.emoji_events,
                      size: 48,
                      color: badgeColor,
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                widget.badges.length == 1
                    ? 'Badge Earned!'
                    : '${widget.badges.length} Badges Earned!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              ...widget.badges.map((b) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(b.icon, color: badgeColor, size: 28),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                b.description,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Awesome!'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
