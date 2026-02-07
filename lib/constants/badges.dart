import 'package:flutter/material.dart';

/// Definition of a badge that can be earned.
class BadgeDefinition {
  final String id;
  final String name;
  final String description;
  final String iconName;

  /// Minimum trust score required to earn this badge, or null if not score-based.
  final int? trustScoreThreshold;

  /// Whether this badge is awarded based on special criteria (not trust score).
  final bool isSpecial;

  const BadgeDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    this.trustScoreThreshold,
    this.isSpecial = false,
  });

  IconData get icon {
    switch (iconName) {
      case 'handshake':
        return Icons.handshake;
      case 'favorite':
        return Icons.favorite;
      case 'star':
        return Icons.star;
      case 'military_tech':
        return Icons.military_tech;
      case 'auto_awesome':
        return Icons.auto_awesome;
      case 'verified_user':
        return Icons.verified_user;
      default:
        return Icons.emoji_events;
    }
  }
}

/// All badges available in MicroHelp, ordered by difficulty.
const availableBadges = <BadgeDefinition>[
  BadgeDefinition(
    id: 'founding_neighbor',
    name: 'Founding Neighbor',
    description: 'Joined during the beta launch',
    iconName: 'auto_awesome',
    isSpecial: true,
  ),
  BadgeDefinition(
    id: 'verified',
    name: 'Verified',
    description: 'Identity verified by MicroHelp',
    iconName: 'verified_user',
    isSpecial: true,
  ),
  BadgeDefinition(
    id: 'first_help',
    name: 'First Help',
    description: 'Complete your first task',
    iconName: 'handshake',
    trustScoreThreshold: 1,
  ),
  BadgeDefinition(
    id: 'helpful_neighbor',
    name: 'Helpful Neighbor',
    description: 'Complete 5 tasks',
    iconName: 'favorite',
    trustScoreThreshold: 5,
  ),
  BadgeDefinition(
    id: 'community_hero',
    name: 'Community Hero',
    description: 'Complete 10 tasks',
    iconName: 'star',
    trustScoreThreshold: 10,
  ),
  BadgeDefinition(
    id: 'neighborhood_legend',
    name: 'Neighborhood Legend',
    description: 'Complete 25 tasks',
    iconName: 'military_tech',
    trustScoreThreshold: 25,
  ),
];

/// Returns badge definitions that should be awarded for the given trust score,
/// excluding any already earned (by id).
List<BadgeDefinition> badgesToAward(int newTrustScore, Set<String> earnedIds) {
  return availableBadges
      .where((b) =>
          b.trustScoreThreshold != null &&
          newTrustScore >= b.trustScoreThreshold! &&
          !earnedIds.contains(b.id))
      .toList();
}
