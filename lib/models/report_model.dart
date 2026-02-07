import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String reporterId;
  final String reportedUserId;
  final String? reportedPostId;
  final String category;
  final String description;
  final DateTime timestamp;
  final String status;

  const ReportModel({
    required this.reporterId,
    required this.reportedUserId,
    this.reportedPostId,
    required this.category,
    this.description = '',
    required this.timestamp,
    this.status = 'pending',
  });

  Map<String, dynamic> toFirestore() {
    return {
      'reporterId': reporterId,
      'reportedUserId': reportedUserId,
      if (reportedPostId != null) 'reportedPostId': reportedPostId,
      'category': category,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status,
    };
  }
}
