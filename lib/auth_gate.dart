import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:picom/screens/auth/auth_screen.dart';
import 'package:picom/screens/etc/home_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData) {
          return HomeScreen();
        } else {
          return const AuthScreen();
        }
      },
    );
  }
}
