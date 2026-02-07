import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String? profilePic;
  final int trustScore;
  final DateTime? lastActive;
  final GeoPoint? location;
  final String? fcmToken;
  final String? gender;
  final String? ageRange;
  final DateTime? birthday;
  final String? neighborhood;
  final String? bio;
  final DateTime? createdAt;
  final bool idVerified;
  final List<String> blockedUsers;

  const UserModel({
    required this.id,
    required this.name,
    this.profilePic,
    this.trustScore = 0,
    this.lastActive,
    this.location,
    this.fcmToken,
    this.gender,
    this.ageRange,
    this.birthday,
    this.neighborhood,
    this.bio,
    this.createdAt,
    this.idVerified = false,
    this.blockedUsers = const [],
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      profilePic: data['profilePic'] as String?,
      trustScore: (data['trustScore'] as int?) ?? 0,
      lastActive: (data['lastActive'] as Timestamp?)?.toDate(),
      location: data['location'] as GeoPoint?,
      fcmToken: data['fcmToken'] as String?,
      gender: data['gender'] as String?,
      ageRange: data['ageRange'] as String?,
      birthday: (data['birthday'] as Timestamp?)?.toDate(),
      neighborhood: data['neighborhood'] as String?,
      bio: data['bio'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      idVerified: (data['idVerified'] as bool?) ?? false,
      blockedUsers: List<String>.from(data['blockedUsers'] as List? ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      if (profilePic != null) 'profilePic': profilePic,
      'trustScore': trustScore,
      if (lastActive != null) 'lastActive': Timestamp.fromDate(lastActive!),
      if (location != null) 'location': location,
      if (fcmToken != null) 'fcmToken': fcmToken,
      if (gender != null) 'gender': gender,
      if (ageRange != null) 'ageRange': ageRange,
      if (birthday != null) 'birthday': Timestamp.fromDate(birthday!),
      if (neighborhood != null) 'neighborhood': neighborhood,
      if (bio != null) 'bio': bio,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      'idVerified': idVerified,
      if (blockedUsers.isNotEmpty) 'blockedUsers': blockedUsers,
    };
  }

  /// How long ago the account was created, as a human-readable string.
  String? get accountAge {
    if (createdAt == null) return null;
    final days = DateTime.now().difference(createdAt!).inDays;
    if (days < 1) return 'Joined today';
    if (days == 1) return 'Joined 1 day ago';
    if (days < 30) return 'Joined $days days ago';
    final months = days ~/ 30;
    if (months == 1) return 'Joined 1 month ago';
    return 'Joined $months months ago';
  }
}
