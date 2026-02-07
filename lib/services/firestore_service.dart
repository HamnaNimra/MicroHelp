import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import '../models/message_model.dart';
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
}
