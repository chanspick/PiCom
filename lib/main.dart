import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';  // ✅ 추가
import 'package:flutter_gemini/flutter_gemini.dart';
import 'firebase_options.dart';
import 'widgets/auth_wrapper.dart';
import 'screens/etc/home_screen.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/pc_assembly_screen.dart';
import 'package:provider/provider.dart';
import 'package:picom/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ===== Firebase App Check 활성화 (내부 테스트용) =====
  // 🔧 디버그 모드: 자동 생성 토큰 사용 (에뮬레이터/개발)
  // 📱 릴리즈 모드: 정적 토큰 사용 (내부 테스트 APK)
  if (kDebugMode) {
    // 개발 환경 (에뮬레이터, USB 디버깅)
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug,
    );
    print('🔧 App Check: Debug Provider (dynamic token)');
  } else {
    // 내부 테스트 환경 (배포된 APK)
    // ⚠️ 아래 단계를 따라 진행하세요:
    // 1. Firebase Console → App Check → "Add debug token" → "Generate token"
    // 2. 생성된 토큰을 아래에 입력
    // 3. APK 빌드 후 Firebase Console에 토큰 등록 확인
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug,
    );

    // 토큰 자동 갱신 활성화
    await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
    print('📱 App Check: Debug Provider (static token for internal testing)');
  }

  // Gemini 초기화
  Gemini.init(apiKey: "dd716ef59ac082af5307d674520ae676");

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'KREAM',
          theme: ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.deepPurple,
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: Colors.deepPurple,
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardColor: const Color(0xFF1E1E1E),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.white),
              bodyMedium: TextStyle(color: Colors.white70),
              titleLarge: TextStyle(color: Colors.white),
              titleMedium: TextStyle(color: Colors.white),
              titleSmall: TextStyle(color: Colors.white),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E1E1E),
              foregroundColor: Colors.white,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.deepPurple),
                foregroundColor: MaterialStateProperty.all(Colors.white),
              ),
            ),
            colorScheme: ColorScheme.fromSwatch(
              brightness: Brightness.dark,
              primarySwatch: Colors.deepPurple,
            ).copyWith(
              secondary: Colors.amber,
              surface: const Color(0xFF1E1E1E),
              onSurface: Colors.white,
              onPrimary: Colors.white,
            ),
            useMaterial3: true,
          ),
          themeMode: themeProvider.themeMode,
          debugShowCheckedModeBanner: false,
          home: AuthWrapper(),  // ✅ 기존 진입점 유지
          routes: {
            '/home': (context) => HomeScreen(),
            '/auth': (context) => const AuthScreen(),
            '/pc_assembly': (context) => const PcAssemblyScreen(),
          },
        );
      },
    );
  }
}
