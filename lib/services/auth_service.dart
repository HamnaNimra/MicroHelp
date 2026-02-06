import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    return _auth.createUserWithEmailAndPassword(
        email: email, password: password);
  }

  Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<UserCredential?> signInWithApple() async {
    final appleProvider = AppleAuthProvider();
    return _auth.signInWithProvider(appleProvider);
  }

  bool get canSignInWithApple =>
      Platform.isIOS || Platform.isMacOS;

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<UserModel?> getOrCreateUser(User firebaseUser) async {
    final ref = _firestore.collection('users').doc(firebaseUser.uid);
    final doc = await ref.get();

    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }

    final userModel = UserModel(
      id: firebaseUser.uid,
      name: firebaseUser.displayName ?? firebaseUser.email ?? 'User',
      profilePic: firebaseUser.photoURL,
    );
    await ref.set(userModel.toFirestore());
    return userModel;
  }
}
