import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:cloud_firestore/cloud_firestore.dart';  // ✅ 추가
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

  // 1. Firebase 초기화
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('✅ Firebase initialized');

  // 2. App Check 활성화
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );
  print('✅ App Check activated: Debug mode');

  // 3. ✅ Firestore 설정 추가 (핵심!)
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  print('✅ Firestore settings configured');

  // 4. Gemini 초기화
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
            useMaterial3: true,
          ),
          themeMode: themeProvider.themeMode,
          debugShowCheckedModeBanner: false,
          home: AuthWrapper(),
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
