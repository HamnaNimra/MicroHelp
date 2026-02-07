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

  bool get canSignInWithGoogle => true;

  bool get canSignInWithApple => true;

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    return _auth.createUserWithEmailAndPassword(
        email: email, password: password);
  }

  Future<UserCredential?> signInWithGoogle() async {
    final googleProvider = GoogleAuthProvider();
    if (kIsWeb) {
      return _auth.signInWithPopup(googleProvider);
    }
    return _auth.signInWithProvider(googleProvider);
  }

  Future<UserCredential?> signInWithApple() async {
    final appleProvider = AppleAuthProvider();
    if (kIsWeb) {
      return _auth.signInWithPopup(appleProvider);
    }
    return _auth.signInWithProvider(appleProvider);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Links a Google account to the current user.
  Future<void> linkWithGoogle() async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('No signed-in user');
    final googleProvider = GoogleAuthProvider();
    if (kIsWeb) {
      await user.linkWithPopup(googleProvider);
    } else {
      await user.linkWithProvider(googleProvider);
    }
  }

  /// Links an Apple account to the current user.
  Future<void> linkWithApple() async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('No signed-in user');
    final appleProvider = AppleAuthProvider();
    if (kIsWeb) {
      await user.linkWithPopup(appleProvider);
    } else {
      await user.linkWithProvider(appleProvider);
    }
  }

  /// Unlinks a provider from the current user.
  Future<void> unlinkProvider(String providerId) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('No signed-in user');
    await user.unlink(providerId);
  }

  /// Returns the list of linked provider IDs for the current user.
  List<String> getLinkedProviders() {
    final user = _auth.currentUser;
    if (user == null) return [];
    return user.providerData.map((p) => p.providerId).toList();
  }

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

  /// Returns true if this user doc has the required community fields filled in.
  bool isProfileComplete(UserModel user) {
    return user.birthday != null && user.gender != null;
  }

  /// Updates an existing user's profile fields in Firestore.
  Future<void> updateUserProfile(
    String uid, {
    required String name,
    required DateTime birthday,
    required String gender,
    String? neighborhood,
    String? bio,
  }) async {
    final updates = <String, dynamic>{
      'name': name,
      'birthday': Timestamp.fromDate(birthday),
      'gender': gender,
      'ageRange': _computeAgeRange(birthday),
    };
    if (neighborhood != null) updates['neighborhood'] = neighborhood;
    if (bio != null) updates['bio'] = bio;
    await _firestore.collection('users').doc(uid).update(updates);
  }

  /// Returns the primary sign-in provider for the current user.
  /// Returns 'google.com', 'apple.com', 'password', or null.
  String? getSignInProvider() {
    final user = _auth.currentUser;
    if (user == null) return null;
    for (final info in user.providerData) {
      if (info.providerId == 'google.com') return 'google.com';
      if (info.providerId == 'apple.com') return 'apple.com';
    }
    return 'password';
  }

  /// Re-authenticates the user with their password, deletes Firestore data,
  /// then deletes the Firebase Auth account.
  Future<void> deleteAccount(String password) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('No signed-in user');

    // Re-authenticate to prove identity
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );
    await user.reauthenticateWithCredential(credential);

    await _deleteUserData(user);
  }

  /// Re-authenticates via Google or Apple provider, then deletes account.
  Future<void> deleteAccountWithProvider() async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('No signed-in user');

    final provider = getSignInProvider();
    if (provider == 'google.com') {
      final googleProvider = GoogleAuthProvider();
      if (kIsWeb) {
        await user.reauthenticateWithPopup(googleProvider);
      } else {
        await user.reauthenticateWithProvider(googleProvider);
      }
    } else if (provider == 'apple.com') {
      final appleProvider = AppleAuthProvider();
      if (kIsWeb) {
        await user.reauthenticateWithPopup(appleProvider);
      } else {
        await user.reauthenticateWithProvider(appleProvider);
      }
    } else {
      throw StateError('Use deleteAccount(password) for email/password users');
    }

    await _deleteUserData(user);
  }

  Future<void> _deleteUserData(User user) async {
    final uid = user.uid;

    // Delete FCM token
    try {
      await _notificationService.deleteToken();
    } catch (_) {}

    // Delete user's uncompleted posts that have no active chat
    final userPosts = await _firestore
        .collection('posts')
        .where('userId', isEqualTo: uid)
        .get();
    for (final doc in userPosts.docs) {
      final data = doc.data();
      if (data['acceptedBy'] == null) {
        // No helper involved — safe to delete entirely
        await doc.reference.delete();
      } else {
        // Has a chat — mark as deleted user, keep for the other party
        await doc.reference.update({
          'userDeleted': true,
          'completed': true,
        });
      }
    }

    // Mark posts where this user was the helper
    final helpingPosts = await _firestore
        .collection('posts')
        .where('acceptedBy', isEqualTo: uid)
        .get();
    for (final doc in helpingPosts.docs) {
      await doc.reference.update({
        'helperDeleted': true,
        'completed': true,
      });
    }

    // Send a system message in each active chat this user was part of
    final allChatPostIds = <String>{};
    for (final doc in userPosts.docs) {
      if (doc.data()['acceptedBy'] != null) allChatPostIds.add(doc.id);
    }
    for (final doc in helpingPosts.docs) {
      allChatPostIds.add(doc.id);
    }
    for (final postId in allChatPostIds) {
      await _firestore
          .collection('messages')
          .doc(postId)
          .collection('messages')
          .add({
        'senderId': 'system',
        'text': 'This user has deleted their account.',
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    // Delete badges sub-collection
    final badgesSnap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('badges')
        .get();
    for (final doc in badgesSnap.docs) {
      await doc.reference.delete();
    }

    // Delete user document
    await _firestore.collection('users').doc(uid).delete();

    // Delete Firebase Auth account
    await user.delete();
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
