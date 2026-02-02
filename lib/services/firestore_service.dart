import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import '../models/message_model.dart';

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

  Future<void> completePost(String postId) async {
    await _posts.doc(postId).update({'completed': true});
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
