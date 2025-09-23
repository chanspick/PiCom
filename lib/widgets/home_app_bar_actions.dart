import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:picom/services/auth_service.dart';
import 'package:picom/screens/profile/profile_screen.dart'; // Added import

class HomeAppBarActions extends StatelessWidget {
  const HomeAppBarActions({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Row(
      children: [
        // 알림(벨) 아이콘 추가
        IconButton(
          icon: const Icon(Icons.notifications_none), // 또는 Icons.notifications
          onPressed: () {
            // TODO: 알림 화면으로 이동
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('알림 기능은 아직 구현되지 않았습니다.')),
            );
          },
        ),
        GestureDetector(
          onTap: () {
            if (user != null) { // Only navigate if user is logged in
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(userId: user.uid),
                ),
              );
            } else {
              // Optionally, show a message or navigate to login if user is guest
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('로그인 후 프로필을 볼 수 있습니다.')),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundImage: user?.photoURL != null
                      ? NetworkImage(user!.photoURL!)
                      : null,
                  child: user?.photoURL == null
                      ? const Icon(Icons.person, size: 18)
                      : null,
                ),
                // 기존 SizedBox(height: 4)와 Text 위젯 삭제
              ],
            ),
          ),
        ),
        // 삼단 바(햄버거) 메뉴 아이콘 삭제
      ],
    );
  }
}