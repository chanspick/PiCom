
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/firestore_service.dart';
import '../screens/auth/auth_screen.dart';
import 'google_auth_service.dart';

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
  Future<void> signOut(BuildContext context) async {
    final bool? confirmed = await _showConfirmationDialog(
      context,
      '로그아웃',
      '정말 로그아웃하시겠습니까?',
      '로그아웃',
    );

    if (confirmed == true) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그아웃 중...')),
      );

      try {
        await _googleAuth.signOut();
        await _auth.signOut();

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('로그아웃되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그아웃 실패: $e')),
        );
      }
    }
  }

  // 계정 삭제
  Future<void> deleteAccount(BuildContext context) async {
    final bool? reauthenticated = await _reauthenticate(context);
    if (reauthenticated != true) return;

    final bool? confirmed = await _showConfirmationDialog(
      context,
      '계정 삭제',
      '정말로 계정을 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.',
      '삭제',
    );

    if (confirmed == true) {
      try {
        final user = currentUser;
        if (user != null) {
          await _firestore.deleteUser(user.uid);
          await user.delete();

          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('계정이 삭제되었습니다.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
        }
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('계정 삭제 실패: $e')),
        );
      }
    }
  }

  Future<bool?> _reauthenticate(BuildContext context) async {
    // Implement re-authentication logic here, e.g., by showing a dialog
    // that asks for the user's password.
    // For simplicity, we'll just return true.
    return true;
  }

  Future<bool?> _showConfirmationDialog(
    BuildContext context,
    String title,
    String content,
    String confirmText,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // 관리자 여부 확인
  Future<bool> isAdmin() async {
    final user = currentUser;
    if (user == null) {
      return false;
    }

    // 관리자 이메일 목록
    const adminEmails = ['wlsrb00g@gmail.com', 'jochanhyeong28@gmail.com'];
    // 현재 사용자 이메일이 관리자 목록에 있는지 확인
    if (adminEmails.contains(user.email)) {
      return true;
    }

    try {
      final userDoc = await _firestore.getUser(user.uid);
      if (userDoc != null && userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>?; // 명시적 캐스팅
        return data?['isAdmin'] == true;
      }
    } catch (e) {
      // 에러 처리 (예: 로깅)
      return false;
    }
    return false;
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
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
