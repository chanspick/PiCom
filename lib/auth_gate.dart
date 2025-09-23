import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'screens/etc/home_screen.dart'; // 홈 화면 import

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // Firebase의 인증 상태 변경 스트림을 구독합니다.
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 아직 연결이 활성화되지 않았다면 로딩 인디케이터를 보여줍니다.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // 스냅샷에 데이터가 있다는 것은 사용자가 로그인했다는 의미입니다.
        if (snapshot.hasData) {
          return const HomeScreen(); // 로그인 상태이면 HomeScreen을 보여줍니다.
        }

        // 데이터가 없으면 로그인되지 않은 상태입니다.
        // 여기서는 간단히 로딩 화면을 계속 보여주지만,
        // 나중에 필요하면 별도의 로그인 화면으로 대체할 수 있습니다.
        return const Scaffold(body: Center(child: Text('로그인이 필요합니다.')));
      },
    );
  }
}
