import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/auth_screen.dart';

class AuthUtils {
  /// Firestore 쓰기 작업 시 권한 오류 처리 및 로그인 유도
  static Future<void> tryWriteWithLoginGuard(
      BuildContext context,
      Future<void> Function() writeAction,
      ) async {
    try {
      await writeAction();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        // PERMISSION_DENIED 발생 시 로그인 안내 및 이동
        if (context.mounted) {
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
      } else {
        // 기타 오류 처리
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('오류가 발생했습니다: ${e.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // 예상치 못한 오류 처리
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('알 수 없는 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 인증 상태 확인 및 로그인 유도
  static bool requireAuth(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
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
      return false;
    }
    return true;
  }

  /// 익명 사용자 확인
  static bool isAnonymous() {
    final user = FirebaseAuth.instance.currentUser;
    return user == null || user.isAnonymous;
  }
}
