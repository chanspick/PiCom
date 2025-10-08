import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '222126078513-gud2gesn3gkei4pebeohe51b0psrdbsb.apps.googleusercontent.com',
  );
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> signIn() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      // Error handling can be improved here
      return null;
    }
  }

  Future<GoogleSignInAuthentication?> getGoogleAuthentication() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      return null;
    }
    return await googleUser.authentication;
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      // Error handling can be improved here
    }
  }

  Future<void> disconnect() async {
    try {
      await _googleSignIn.disconnect();
    } catch (e) {
      // Error handling can be improved here
    }
  }
}
