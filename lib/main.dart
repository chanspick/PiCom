import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 앱 실행 시 자동으로 익명 로그인 시도
  final auth = FirebaseAuth.instance;
  if (auth.currentUser == null) {
    try {
      await auth.signInAnonymously();
    } catch (e) {
      // 익명 로그인 실패 시 에러 처리 (필요시 스낵바, 로깅 등 추가)
      debugPrint('익명 로그인 실패: $e');
    }
  }

  runApp(const MyApp());
}
