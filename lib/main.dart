import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart'; // FlutterFire CLI가 생성한 설정
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 익명으로 로그인 (한 번만 실행하면, 앱이 살아있는 동안 session 유지됨)
  try {
    await FirebaseAuth.instance.signInAnonymously();
    debugPrint('✅ 익명 로그인 성공');
  } on FirebaseAuthException catch (e) {
    debugPrint('❌ 익명 로그인 실패: ${e.code} ${e.message}');
  }

  runApp(const MyApp());
}
