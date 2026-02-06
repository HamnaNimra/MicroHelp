// Stub implementation for platforms where google_sign_in is not supported
class GoogleSignIn {
  GoogleSignIn({List<String>? scopes});

  Future<GoogleSignInAccount?> signIn() async {
    throw UnsupportedError('Google Sign-In is not supported on this platform');
  }

  Future<GoogleSignInAccount?> signOut() async => null;
}

class GoogleSignInAccount {
  Future<GoogleSignInAuthentication> get authentication async {
    throw UnsupportedError('Google Sign-In is not supported on this platform');
  }
}

class GoogleSignInAuthentication {
  String? get accessToken => null;
  String? get idToken => null;
}
