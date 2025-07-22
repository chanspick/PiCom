import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GoogleAuthService {
final GoogleSignIn _googleSignIn = GoogleSignIn();
final FirebaseAuth _auth = FirebaseAuth.instance;

// 구글 로그인
Future<User?> signIn() async {
try {
final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
if (googleUser == null) return null;

final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
final credential = GoogleAuthProvider.credential(
accessToken: googleAuth.accessToken,
idToken: googleAuth.idToken,
);

final UserCredential userCredential = await _auth.signInWithCredential(credential);
return userCredential.user;
} catch (e) {
print('구글 로그인 실패: $e');
return null;
}
}

// 구글 인증 정보 가져오기 (계정 연결용)
Future<GoogleSignInAuthentication> getGoogleAuthentication() async {
final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
if (googleUser == null) throw Exception('구글 로그인 취소');

return await googleUser.authentication;
}

// 로그아웃
Future<void> signOut() async {
try {
await _googleSignIn.signOut();
await _auth.signOut();
} catch (e) {
print('구글 로그아웃 실패: $e');
}
}

// 연결 해제
Future<void> disconnect() async {
try {
await _googleSignIn.disconnect();
} catch (e) {
print('구글 연결 해제 실패: $e');
}
}
}
