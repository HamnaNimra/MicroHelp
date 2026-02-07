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

  Future<void> acceptPost(String postId, String userId) async {
    await _posts.doc(postId).update({'acceptedBy': userId});
  }

  /// Completes the post. If [currentUserId] is the helper (acceptedBy),
  /// also increments their trust score in a transaction (works on Spark plan without Cloud Functions).
  Future<void> completePost(String postId, String currentUserId) async {
    final postRef = _posts.doc(postId);
    final postSnap = await postRef.get();
    if (!postSnap.exists || postSnap.data() == null) return;
    final data = postSnap.data()!;
    if (data['completed'] == true) return;

    final helperId = data['acceptedBy'] as String?;
    final isHelper = helperId == currentUserId;

    if (isHelper && helperId != null) {
      final userRef = _firestore.collection('users').doc(helperId);
      await _firestore.runTransaction((tx) async {
        final post = await tx.get(postRef);
        if (post.data()?['completed'] == true) return;
        tx.update(postRef, {'completed': true});
        final userSnap = await tx.get(userRef);
        final current = (userSnap.data()?['trustScore'] as int?) ?? 0;
        tx.update(userRef, {'trustScore': current + 1});
      });
    } else {
      await postRef.update({'completed': true});
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
}
