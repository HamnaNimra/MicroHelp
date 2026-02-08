import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import '../models/message_model.dart';
import '../models/report_model.dart';
import '../constants/badges.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _posts =>
      _firestore.collection('posts');

  CollectionReference<Map<String, dynamic>> _messages(String postId) =>
      _firestore.collection('messages').doc(postId).collection('messages');

  Future<void> createPost(PostModel post) async {
    await _posts.add(post.toFirestore());
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getActivePosts() {
    return _posts
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .where('completed', isEqualTo: false)
        .snapshots();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getPost(String postId) async {
    return _posts.doc(postId).get();
  }

  Future<void> updatePost(String postId, Map<String, dynamic> updates) async {
    await _posts.doc(postId).update(updates);
  }

  Future<void> deletePost(String postId) async {
    await _posts.doc(postId).delete();
  }

  /// Accept a post (set acceptedBy to current user). Fails if post is missing,
  /// already accepted, or completed. Use a read-then-write to avoid races.
  Future<void> acceptPost(String postId, String userId) async {
    final ref = _posts.doc(postId);
    final snap = await ref.get();
    if (!snap.exists || snap.data() == null) {
      throw AcceptPostException('Post no longer exists.');
    }
    final data = snap.data()!;
    if (data['completed'] == true) {
      throw AcceptPostException('This task is already completed.');
    }
    final existing = data['acceptedBy'] as String?;
    if (existing != null) {
      throw AcceptPostException('Someone else already accepted this post.');
    }
    await ref.update({'acceptedBy': userId});
  }

  /// Helper or owner requests completion. Sets completionRequestedBy
  /// so the other party can approve.
  Future<void> requestCompletion(String postId, String requestedByUid) async {
    await _posts.doc(postId).update({
      'completionRequestedBy': requestedByUid,
    });
  }

  /// Approves a completion request (called by the other party).
  /// Marks the post as completed and awards trust score to the helper.
  Future<void> approveCompletion(String postId) async {
    final postRef = _posts.doc(postId);
    final postSnap = await postRef.get();
    if (!postSnap.exists || postSnap.data() == null) return;
    final data = postSnap.data()!;
    if (data['completed'] == true) return;

    final helperId = data['acceptedBy'] as String?;

    if (helperId != null) {
      final userRef = _firestore.collection('users').doc(helperId);
      await _firestore.runTransaction((tx) async {
        // All reads must come before any writes in a transaction
        final post = await tx.get(postRef);
        final userSnap = await tx.get(userRef);
        if (post.data()?['completed'] == true) return;
        final current = (userSnap.data()?['trustScore'] as int?) ?? 0;
        tx.update(postRef, {
          'completed': true,
          'completionRequestedBy': FieldValue.delete(),
        });
        tx.update(userRef, {'trustScore': current + 1});
      });
    } else {
      await postRef.update({
        'completed': true,
        'completionRequestedBy': FieldValue.delete(),
      });
    }
  }

  /// Direct completion (owner can always directly complete their own task).
  Future<void> completePost(String postId, String currentUserId) async {
    final postRef = _posts.doc(postId);
    final postSnap = await postRef.get();
    if (!postSnap.exists || postSnap.data() == null) return;
    final data = postSnap.data()!;
    if (data['completed'] == true) return;

    final helperId = data['acceptedBy'] as String?;
    final isOwner = data['userId'] == currentUserId;

    // Owner completing = direct approve, give helper trust score
    if (isOwner && helperId != null) {
      final userRef = _firestore.collection('users').doc(helperId);
      await _firestore.runTransaction((tx) async {
        // All reads must come before any writes in a transaction
        final post = await tx.get(postRef);
        final userSnap = await tx.get(userRef);
        if (post.data()?['completed'] == true) return;
        final current = (userSnap.data()?['trustScore'] as int?) ?? 0;
        tx.update(postRef, {
          'completed': true,
          'completionRequestedBy': FieldValue.delete(),
        });
        tx.update(userRef, {'trustScore': current + 1});
      });
    } else {
      await postRef.update({
        'completed': true,
        'completionRequestedBy': FieldValue.delete(),
      });
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getMessages(String postId) {
    return _messages(postId)
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  Future<void> sendMessage(String postId, MessageModel message) async {
    await _messages(postId).add(message.toFirestore());
  }

  // --------------- Per-chat sharing preferences ---------------

  /// Returns a real-time stream of a user's sharing preferences for a specific chat.
  Stream<DocumentSnapshot<Map<String, dynamic>>> getChatSharing(
      String postId, String userId) {
    return _firestore
        .collection('messages')
        .doc(postId)
        .collection('sharing')
        .doc(userId)
        .snapshots();
  }

  /// Updates sharing preferences for the current user in a specific chat.
  /// Once shareName/sharePhone/sharePhoto are enabled, they cannot be disabled.
  /// shareLocation can be toggled freely.
  Future<void> updateChatSharing(
    String postId,
    String userId, {
    bool? shareName,
    bool? sharePhone,
    bool? sharePhoto,
    bool? shareLocation,
  }) async {
    final ref = _firestore
        .collection('messages')
        .doc(postId)
        .collection('sharing')
        .doc(userId);

    final doc = await ref.get();
    final current = doc.data() ?? {};

    final updates = <String, dynamic>{};
    // Once enabled, name/phone/photo cannot be un-shared
    if (shareName == true && current['shareName'] != true) {
      updates['shareName'] = true;
    }
    if (sharePhone == true && current['sharePhone'] != true) {
      updates['sharePhone'] = true;
    }
    if (sharePhoto == true && current['sharePhoto'] != true) {
      updates['sharePhoto'] = true;
    }
    // Location can be toggled freely
    if (shareLocation != null) {
      updates['shareLocation'] = shareLocation;
    }

    if (updates.isNotEmpty) {
      await ref.set(updates, SetOptions(merge: true));
    }
  }

  /// Gets a user document by ID.
  Future<DocumentSnapshot<Map<String, dynamic>>> getUser(String userId) {
    return _firestore.collection('users').doc(userId).get();
  }

  /// Checks trust score against badge thresholds and awards any new badges.
  /// Returns the list of newly awarded badge definitions.
  Future<List<BadgeDefinition>> checkAndAwardBadges(String userId) async {
    final userRef = _firestore.collection('users').doc(userId);
    final badgesRef = userRef.collection('badges');

    final userSnap = await userRef.get();
    final trustScore = (userSnap.data()?['trustScore'] as int?) ?? 0;

    final existingBadges = await badgesRef.get();
    final earnedIds = existingBadges.docs.map((d) => d.id).toSet();

    final newBadges = badgesToAward(trustScore, earnedIds);
    final now = DateTime.now();

    for (final badge in newBadges) {
      await badgesRef.doc(badge.id).set({
        'name': badge.name,
        'description': badge.description,
        'iconName': badge.iconName,
        'earnedAt': Timestamp.fromDate(now),
      });
    }

    return newBadges;
  }

  /// Awards the Founding Neighbor badge if not already earned.
  Future<bool> awardFoundingNeighborBadge(String userId) async {
    final badgeRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('badges')
        .doc('founding_neighbor');

    final existing = await badgeRef.get();
    if (existing.exists) return false;

    final badge = availableBadges[0]; // founding_neighbor
    await badgeRef.set({
      'name': badge.name,
      'description': badge.description,
      'iconName': badge.iconName,
      'earnedAt': Timestamp.fromDate(DateTime.now()),
    });
    return true;
  }

  // --------------- Report & Block ---------------

  /// Submit a report to the reports collection.
  Future<void> createReport(ReportModel report) async {
    await _firestore.collection('reports').add(report.toFirestore());
  }

  /// Block a user. Adds [blockedUserId] to the current user's blockedUsers array.
  Future<void> blockUser(String currentUserId, String blockedUserId) async {
    await _firestore.collection('users').doc(currentUserId).update({
      'blockedUsers': FieldValue.arrayUnion([blockedUserId]),
    });
  }

  /// Unblock a user.
  Future<void> unblockUser(String currentUserId, String blockedUserId) async {
    await _firestore.collection('users').doc(currentUserId).update({
      'blockedUsers': FieldValue.arrayRemove([blockedUserId]),
    });
  }

  /// Get the current user's blocked user IDs.
  Future<List<String>> getBlockedUsers(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return List<String>.from(doc.data()?['blockedUsers'] as List? ?? []);
  }
}

/// Thrown when acceptPost fails due to post state (already accepted, completed, or missing).
class AcceptPostException implements Exception {
  final String message;
  AcceptPostException(this.message);
  @override
  String toString() => message;
}
