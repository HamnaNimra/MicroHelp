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
    try {
      await _notificationService.deleteToken();
    } catch (_) {}
    await _auth.signOut();
  }

  Future<UserModel?> getOrCreateUser(
    User firebaseUser, {
    String? displayName,
    DateTime? birthday,
    String? gender,
    String? neighborhood,
    String? bio,
  }) async {
    final ref = _firestore.collection('users').doc(firebaseUser.uid);
    final doc = await ref.get();

    if (doc.exists) {
      // Save FCM token (non-blocking — may fail on web)
      _notificationService.saveToken(firebaseUser.uid).catchError((_) {});
      return UserModel.fromFirestore(doc);
    }

    // New user - create document
    final now = DateTime.now();
    final name = displayName ??
        firebaseUser.displayName ??
        firebaseUser.email ??
        'User';
    final userModel = UserModel(
      id: firebaseUser.uid,
      name: name,
      profilePic: firebaseUser.photoURL,
      createdAt: now,
      birthday: birthday,
      gender: gender,
      ageRange: birthday != null ? _computeAgeRange(birthday) : null,
      neighborhood: neighborhood,
      bio: bio,
    );
    await ref.set(userModel.toFirestore());

    // Update Firebase Auth display name if provided
    if (displayName != null && firebaseUser.displayName != displayName) {
      await firebaseUser.updateDisplayName(displayName);
    }

    // Save FCM token (non-blocking — may fail on web)
    _notificationService.saveToken(firebaseUser.uid).catchError((_) {});

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

  String _computeAgeRange(DateTime birthday) {
    final now = DateTime.now();
    int age = now.year - birthday.year;
    if (now.month < birthday.month ||
        (now.month == birthday.month && now.day < birthday.day)) {
      age--;
    }
    if (age <= 25) return '18-25';
    if (age <= 35) return '26-35';
    if (age <= 45) return '36-45';
    if (age <= 60) return '46-60';
    return '60+';
  }
}
