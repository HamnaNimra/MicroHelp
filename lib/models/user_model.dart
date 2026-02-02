import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String? profilePic;
  final int trustScore;
  final DateTime? lastActive;
  final GeoPoint? location;

  const UserModel({
    required this.id,
    required this.name,
    this.profilePic,
    this.trustScore = 0,
    this.lastActive,
    this.location,
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
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      if (profilePic != null) 'profilePic': profilePic,
      'trustScore': trustScore,
      if (lastActive != null) 'lastActive': Timestamp.fromDate(lastActive!),
      if (location != null) 'location': location,
    };
  }
}
