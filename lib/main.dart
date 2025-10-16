import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
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
          title: 'KREAM',
          theme: ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.deepPurple,
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: Colors.deepPurple,
            scaffoldBackgroundColor: const Color(0xFF121212), // Very dark grey
            cardColor: const Color(0xFF1E1E1E), // Slightly lighter grey for cards
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
              onPrimary: Colors.white, // Explicitly set onPrimary for text on buttons
            ),
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
