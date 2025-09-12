import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 구글 로그인
  Future<User?> signIn() async {
    try {
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      // TODO: Handle error properly
      return null;
    }
  }

  // 구글 인증 정보 가져오기 (계정 연결용)
  Future<GoogleSignInAuthentication?> getGoogleAuthentication() async {
    final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

    return googleUser.authentication;
  }

  // 로그아웃
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      // TODO: Handle error properly
    }
  }

  // 연결 해제
  Future<void> disconnect() async {
    try {
      await _googleSignIn.disconnect();
    } catch (e) {
      // TODO: Handle error properly
    }
  }
}