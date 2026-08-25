import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:google_sign_in/google_sign_in.dart';

/// Wraps Firebase Authentication. Guest (anonymous) sign-in is automatic and
/// silent; Google sign-in upgrades/links the current guest account so local
/// progress carries over.
class AuthService {
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  fb_auth.User? get currentUser => _auth.currentUser;
  bool get hasSession => _auth.currentUser != null;
  bool get isAnonymous => _auth.currentUser?.isAnonymous ?? true;
  String? get email => _auth.currentUser?.email;

  Stream<fb_auth.User?> get authStateChanges => _auth.authStateChanges();

  Future<String?> get idToken async => _auth.currentUser?.getIdToken();

  Future<fb_auth.User> ensureSignedIn() async {
    final existing = _auth.currentUser;
    if (existing != null) return existing;
    final credential = await _auth.signInAnonymously();
    return credential.user!;
  }

  Future<fb_auth.User> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Google sign-in cancelled');
    }
    final googleAuth = await googleUser.authentication;
    final credential = fb_auth.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final current = _auth.currentUser;
    if (current != null && current.isAnonymous) {
      try {
        final result = await current.linkWithCredential(credential);
        return result.user!;
      } on fb_auth.FirebaseAuthException catch (e) {
        if (e.code == 'credential-already-in-use') {
          final result = await _auth.signInWithCredential(credential);
          return result.user!;
        }
        rethrow;
      }
    }

    final result = await _auth.signInWithCredential(credential);
    return result.user!;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
