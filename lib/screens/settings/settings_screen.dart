
import 'package:flutter/material.dart';
import 'package:picom/services/auth_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '위험한 작업',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const Divider(),
            ListTile(
              title: const Text('로그아웃', style: TextStyle(color: Colors.red)),
              onTap: () => authService.signOut(context),
            ),
            ListTile(
              title: const Text('계정 삭제', style: TextStyle(color: Colors.grey)),
              onTap: () => authService.deleteAccount(context),
            ),
          ],
        ),
      ),
    );
  }
}
