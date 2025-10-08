import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:picom/services/firestore_service.dart';
import 'package:picom/screens/auth/auth_screen.dart';
import 'package:picom/services/google_auth_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleAuthService _googleAuth = GoogleAuthService();
  final FirestoreService _firestore = FirestoreService();

  static const List<String> _adminEmails = ['wlsrb00g@gmail.com', 'jochanhyeong28@gmail.com'];

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  bool get isAnonymous => currentUser?.isAnonymous ?? true;

  bool get isLoggedIn => currentUser != null;

  Future<User?> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      final user = userCredential.user;

      if (user != null) {
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
      debugPrint('Error during anonymous sign-in: $e');
      return null;
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      final user = await _googleAuth.signIn();

      if (user != null) {
        if (currentUser?.isAnonymous == true) {
          await _linkAnonymousWithGoogle(user);
        }

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
      debugPrint('Error during Google sign-in: $e');
      return null;
    }
  }

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
      debugPrint('Error linking anonymous account: $e');
    }
  }

  Future<void> signOut(BuildContext context) async {
    final bool? confirmed = await _showConfirmationDialog(
      context,
      '로그아웃',
      '정말 로그아웃하시겠습니까?',
      '로그아웃',
    );

    if (confirmed == true) {
      if (!context.mounted) return;
      _showSnackBar(context, '로그아웃 중...');

      try {
        await _googleAuth.signOut();
        await _auth.signOut();

        if (!context.mounted) return;
        _showSnackBar(context, '로그아웃되었습니다.', isError: false);
        _navigateToAuthScreen(context);
      } catch (e) {
        if (!context.mounted) return;
        _showSnackBar(context, '로그아웃 실패: $e');
      }
    }
  }

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
          _showSnackBar(context, '계정이 삭제되었습니다.', isError: false);
          _navigateToAuthScreen(context);
        }
      } catch (e) {
        if (!context.mounted) return;
        _showSnackBar(context, '계정 삭제 실패: $e');
      }
    }
  }

  Future<bool?> _reauthenticate(BuildContext context) async {
    // For simplicity, this is not fully implemented.
    // In a real app, you would show a dialog to re-enter credentials.
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

  Future<bool> isAdmin() async {
    final user = currentUser;
    if (user == null) {
      return false;
    }

    if (_adminEmails.contains(user.email)) {
      return true;
    }

    try {
      final userDoc = await _firestore.getUser(user.uid);
      if (userDoc != null && userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>?;
        return data?['isAdmin'] == true;
      }
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      return false;
    }
    return false;
  }

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

  bool requireAuth(BuildContext context) {
    if (currentUser == null) {
      _showLoginRequired(context);
      return false;
    }
    return true;
  }

  void _showLoginRequired(BuildContext context) {
    _showSnackBar(context, '로그인이 필요합니다.', color: Colors.orange);
    _navigateToAuthScreen(context);
  }

  void _showError(BuildContext context, String message) {
    _showSnackBar(context, message, isError: true);
  }

  void _showSnackBar(BuildContext context, String message, {bool isError = false, Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color ?? (isError ? Colors.red : Colors.green),
      ),
    );
  }

  void _navigateToAuthScreen(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
  }
}