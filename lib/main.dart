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

  // ✅ App Check 초기화 (Firebase 초기화 직후)
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,  // 개발용
    appleProvider: AppleProvider.debug,      // 개발용
    webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
  );

  // Gemini 초기화
  // TODO: 여기에 자신의 Gemini API 키를 입력하세요.
  Gemini.init(apiKey: "YOUR_API_KEY");

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
          title: 'PiCom',
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
                backgroundColor: WidgetStateProperty.all(Colors.deepPurple),
                foregroundColor: WidgetStateProperty.all(Colors.white),
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
