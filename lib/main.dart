import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'widgets/auth_wrapper.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';

void main() async {
WidgetsFlutterBinding.ensureInitialized();

// Firebase 초기화
await Firebase.initializeApp(
options: DefaultFirebaseOptions.currentPlatform,
);

runApp(const MyApp());
}

class MyApp extends StatelessWidget {
const MyApp({super.key});

@override
Widget build(BuildContext context) {
return MaterialApp(
title: 'KREAM',
theme: ThemeData(
primarySwatch: Colors.deepPurple,
useMaterial3: true,
),
debugShowCheckedModeBanner: false,
home: AuthWrapper(),
routes: {
'/home': (context) => const HomeScreen(),
'/auth': (context) => const AuthScreen(),
},
);
}
}
