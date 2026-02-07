import 'package:cloud_firestore/cloud_firestore.dart';

class BadgeModel {
  final String id;
  final String name;
  final String description;
  final String iconName;
  final DateTime? earnedAt;

  const BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    this.earnedAt,
  });

  factory BadgeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return BadgeModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      iconName: data['iconName'] as String? ?? 'emoji_events',
      earnedAt: (data['earnedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'iconName': iconName,
      if (earnedAt != null) 'earnedAt': Timestamp.fromDate(earnedAt!),
    };
  }
}
