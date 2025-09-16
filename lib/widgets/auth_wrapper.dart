import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../screens/auth_screen.dart';
import '../screens/home_screen.dart';

class AuthWrapper extends StatelessWidget {
  final AuthService _authService = AuthService();

  AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        // 연결 상태 확인 중
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 사용자가 로그인되어 있는 경우
        if (snapshot.hasData) {
          return const HomeScreen();
        }

        // 사용자가 로그인되어 있지 않은 경우
        return const AuthScreen();
      },
    );
  }
}
