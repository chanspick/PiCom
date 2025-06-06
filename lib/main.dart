import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'app.dart';

Future<void> main() async {
  // Flutter 엔진과 위젯 트리를 바인딩합니다.
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 앱을 초기화합니다.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 현재 로그인된 사용자가 있는지 확인합니다.
  // 사용자가 없으면(null) 익명으로 로그인을 시도합니다.
  if (FirebaseAuth.instance.currentUser == null) {
    try {
      await FirebaseAuth.instance.signInAnonymously();
      debugPrint('✅ 익명 로그인 성공: 새로운 세션을 시작합니다.');
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ 익명 로그인 실패: ${e.code}');
      // 로그인 실패 시 처리할 로직 (예: 에러 화면 표시)
    }
  } else {
    debugPrint('✅ 기존 익명 세션이 유지됩니다. UID: ${FirebaseAuth.instance.currentUser?.uid}');
  }

  runApp(const MyApp());
}
