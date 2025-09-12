import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/google_auth_service.dart';
import '../services/firestore_service.dart';
import '../screens/auth_screen.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleAuthService _googleAuth = GoogleAuthService();
  final FirestoreService _firestore = FirestoreService();

  // 현재 사용자 정보
  User? get currentUser => _auth.currentUser;

  // 인증 상태 변화 스트림
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 익명 사용자 여부 확인
  bool get isAnonymous => currentUser?.isAnonymous ?? true;

  // 로그인 상태 확인
  bool get isLoggedIn => currentUser != null;

  // 익명 로그인
  Future<User?> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      final user = userCredential.user;

      if (user != null) {
        // 익명 사용자 정보를 Firestore에 저장
        await _firestore.createOrUpdateUser(
          uid: user.uid,
          email: '',
          name: 'Guest User',
          photoUrl: null,
          provider: 'anonymous',
        );
      }
      return user;
    } catch (e) {
      // TODO: Handle error properly
      return null;
    }
  }

  // 구글 로그인
  Future<User?> signInWithGoogle() async {
    try {
      final user = await _googleAuth.signIn();

      if (user != null) {
        // 현재 사용자가 익명 사용자인 경우 계정 연결
        if (currentUser?.isAnonymous == true) {
          await _linkAnonymousWithGoogle(user);
        }

        // 사용자 정보를 Firestore에 저장
        await _firestore.createOrUpdateUser(
          uid: user.uid,
          email: user.email ?? '',
          name: user.displayName ?? '',
          photoUrl: user.photoURL,
          provider: 'google',
        );
      }
      return user;
    } catch (e) {
      // TODO: Handle error properly
      return null;
    }
  }

  // 익명 계정을 구글 계정과 연결
  Future<void> _linkAnonymousWithGoogle(User googleUser) async {
    try {
      final googleAuth = await _googleAuth.getGoogleAuthentication();
      if (googleAuth != null) {
        final credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );
        await currentUser?.linkWithCredential(credential);
      }
    } catch (e) {
      // TODO: Handle error properly
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    try {
      await _googleAuth.signOut();
      await _auth.signOut();
    } catch (e) {
      // TODO: Handle error properly
    }
  }

  // 계정 삭제
  Future<void> deleteAccount() async {
    try {
      final user = currentUser;
      if (user != null) {
        await _firestore.deleteUser(user.uid);
        await user.delete();
      }
    } catch (e) {
      // TODO: Handle error properly
    }
  }

  // 인증 필요 작업 실행 (기존 AuthUtils 기능 통합)
  Future<void> tryWriteWithLoginGuard(
    BuildContext context,
    Future<void> Function() writeAction,
  ) async {
    try {
      await writeAction();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        if (context.mounted) {
          _showLoginRequired(context);
        }
      } else {
        if (context.mounted) {
          _showError(context, '오류가 발생했습니다: ${e.message}');
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, '알 수 없는 오류가 발생했습니다: $e');
      }
    }
  }

  // 인증 상태 확인 및 로그인 유도
  bool requireAuth(BuildContext context) {
    if (currentUser == null) {
      _showLoginRequired(context);
      return false;
    }
    return true;
  }

  // 로그인 필요 안내
  void _showLoginRequired(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('로그인이 필요합니다.'),
        backgroundColor: Colors.orange,
      ),
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AuthScreen()),
    );
  }

  // 오류 메시지 표시
  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}