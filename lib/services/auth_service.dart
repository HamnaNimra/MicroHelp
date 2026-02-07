import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../constants/badges.dart';
import 'notification_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService;

  AuthService(this._notificationService);

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  bool get canSignInWithGoogle => false;  // Google Sign-In not available (requires mobile/web platform)

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    return _auth.createUserWithEmailAndPassword(
        email: email, password: password);
  }

  Future<UserCredential?> signInWithGoogle() async {
    throw UnsupportedError('Google Sign-In is not supported on this platform');
  }

  Future<UserCredential?> signInWithApple() async {
    final appleProvider = AppleAuthProvider();
    return _auth.signInWithProvider(appleProvider);
  }

  bool get canSignInWithApple =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS);

  Future<void> signOut() async {
    // Delete FCM token before signing out
    await _notificationService.deleteToken();
    await _auth.signOut();
  }

  Future<UserModel?> getOrCreateUser(User firebaseUser) async {
    final ref = _firestore.collection('users').doc(firebaseUser.uid);
    final doc = await ref.get();

    if (doc.exists) {
      // Existing user - save FCM token
      await _notificationService.saveToken(firebaseUser.uid);
      return UserModel.fromFirestore(doc);
    }

    // New user - create document
    final userModel = UserModel(
      id: firebaseUser.uid,
      name: firebaseUser.displayName ?? firebaseUser.email ?? 'User',
      profilePic: firebaseUser.photoURL,
    );
    await ref.set(userModel.toFirestore());

    // Save FCM token for new user
    await _notificationService.saveToken(firebaseUser.uid);

    // Award Founding Neighbor badge to all beta users
    final badge = availableBadges[0]; // founding_neighbor
    await ref.collection('badges').doc(badge.id).set({
      'name': badge.name,
      'description': badge.description,
      'iconName': badge.iconName,
      'earnedAt': Timestamp.fromDate(DateTime.now()),
    });

    return userModel;
  }
}
