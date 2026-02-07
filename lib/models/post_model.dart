import 'package:cloud_firestore/cloud_firestore.dart';

enum PostType { request, offer }

class PostModel {
  final String id;
  final PostType type;
  final String description;
  final String userId;
  final GeoPoint? location;
  final double radius;
  final bool global;
  final DateTime expiresAt;
  final String? acceptedBy;
  final bool completed;
  final bool anonymous;
  final int? estimatedMinutes;
  final String? posterGender;
  final String? posterAgeRange;
  final String? completionRequestedBy;

  const PostModel({
    this.id = '',
    required this.type,
    required this.description,
    required this.userId,
    this.location,
    this.radius = 0,
    this.global = false,
    required this.expiresAt,
    this.acceptedBy,
    this.completed = false,
    this.anonymous = false,
    this.estimatedMinutes,
    this.posterGender,
    this.posterAgeRange,
    this.completionRequestedBy,
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      type: data['type'] == 'offer' ? PostType.offer : PostType.request,
      description: data['description'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      location: data['location'] as GeoPoint?,
      radius: (data['radius'] as num?)?.toDouble() ?? 0,
      global: data['global'] as bool? ?? false,
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      acceptedBy: data['acceptedBy'] as String?,
      completed: data['completed'] as bool? ?? false,
      anonymous: data['anonymous'] as bool? ?? false,
      estimatedMinutes: data['estimatedMinutes'] as int?,
      posterGender: data['posterGender'] as String?,
      posterAgeRange: data['posterAgeRange'] as String?,
      completionRequestedBy: data['completionRequestedBy'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type == PostType.offer ? 'offer' : 'request',
      'description': description,
      'userId': userId,
      if (location != null) 'location': location,
      'radius': radius,
      'global': global,
      'expiresAt': Timestamp.fromDate(expiresAt),
      if (acceptedBy != null) 'acceptedBy': acceptedBy,
      'completed': completed,
      'anonymous': anonymous,
      if (estimatedMinutes != null) 'estimatedMinutes': estimatedMinutes,
      if (posterGender != null) 'posterGender': posterGender,
      if (posterAgeRange != null) 'posterAgeRange': posterAgeRange,
      if (completionRequestedBy != null) 'completionRequestedBy': completionRequestedBy,
    };
  }
}
