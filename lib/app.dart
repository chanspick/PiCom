import 'package:flutter/material.dart';
import 'auth_gate.dart'; // AuthGate 위젯을 import

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '중고마켓',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
        ),
        scaffoldBackgroundColor: Colors.white,
      ),
      // 앱의 첫 화면을 AuthGate로 설정합니다.
      home: const AuthGate(),
    );
  }
}
