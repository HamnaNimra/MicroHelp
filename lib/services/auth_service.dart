import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

// Conditional import: use real package on mobile/web, stub on desktop
import 'google_sign_in_stub.dart'
    if (dart.library.js_interop) 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn? _googleSignIn = Platform.isWindows ? null : GoogleSignIn(
    scopes: ['email'],
  );

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  bool get canSignInWithGoogle => !Platform.isWindows;

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    return _auth.createUserWithEmailAndPassword(
        email: email, password: password);
  }

  Future<UserCredential?> signInWithGoogle() async {
    if (_googleSignIn == null) {
      throw UnsupportedError('Google Sign-In is not supported on this platform');
    }
    final googleUser = await _googleSignIn?.signIn();
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
    await _googleSignIn?.signOut();
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
