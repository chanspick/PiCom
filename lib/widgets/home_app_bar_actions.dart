import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/auth_screen.dart';
import '../services/auth_service.dart';
import '../utils/auth_utils.dart';

class HomeAppBarActions extends StatelessWidget {
  HomeAppBarActions({Key? key}) : super(key: key);

  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 알림 버튼
        IconButton(
          tooltip: '알림',
          icon: const Icon(Icons.notifications_none),
          onPressed: () => _handleNotificationPress(context),
        ),
        // 장바구니 버튼
        IconButton(
          tooltip: '장바구니',
          icon: const Icon(Icons.shopping_cart_outlined),
          onPressed: () => _handleCartPress(context),
        ),
        // 인증 상태 모니터
        StreamBuilder<User?>(
          stream: _authService.authStateChanges,
          builder: (context, snapshot) {
            final user = snapshot.data;
            final isAnon = (user == null) || user.isAnonymous;
            // 유저 메뉴/로그인 버튼 전환
            if (user != null) {
              return _buildUserMenu(context, user, isAnon);
            } else {
              return _buildLoginButton(context);
            }
          },
        ),
      ],
    );
  }

  void _handleNotificationPress(BuildContext context) {
    if (!AuthUtils.requireAuth(context)) return;
    AuthUtils.tryWriteWithLoginGuard(context, () async {
      final user = FirebaseAuth.instance.currentUser!;
      // 예시: 알림 읽음 처리
      await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .get()
          .then((snapshot) async {
        for (var doc in snapshot.docs) {
          await doc.reference.update({'isRead': true});
        }
      });
      // TODO: 알림 화면 이동
    });
  }

  void _handleCartPress(BuildContext context) {
    if (!AuthUtils.requireAuth(context)) return;
    AuthUtils.tryWriteWithLoginGuard(context, () async {
      final user = FirebaseAuth.instance.currentUser!;
      await FirebaseFirestore.instance
          .collection('cart')
          .where('userId', isEqualTo: user.uid)
          .get();
      // TODO: 장바구니 화면 이동
    });
  }

  Widget _buildUserMenu(BuildContext context, User user, bool isAnon) {
    return PopupMenuButton<String>(
      tooltip: '사용자 메뉴',
      icon: user.photoURL != null
          ? CircleAvatar(radius: 16, backgroundImage: NetworkImage(user.photoURL!))
          : Icon(isAnon ? Icons.person_outline : Icons.account_circle, size: 28),
      onSelected: (value) async {
        switch (value) {
          case 'profile':
            if (isAnon) {
              AuthUtils.showLoginPrompt(context, '프로필');
            } else {
              // TODO: 프로필 화면 이동
            }
            break;
          case 'orders':
            _handleOrdersPress(context);
            break;
          case 'settings':
          // TODO: 설정 화면 이동
            break;
          case 'login':
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
            break;
          case 'logout':
          // 로그아웃 전용 다이얼로그 분기
            AuthUtils.showLogoutDialog(context);
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person_outline, size: 20, color: isAnon ? Colors.grey : null),
              const SizedBox(width: 8),
              Text(isAnon ? '게스트' : (user.displayName ?? '내 프로필')),
            ],
          ),
        ),
        if (!isAnon)
          PopupMenuItem<String>(
            value: 'orders',
            child: Row(
              children: [
                const Icon(Icons.shopping_bag_outlined, size: 20),
                const SizedBox(width: 8),
                const Text('주문 내역'),
              ],
            ),
          ),
        if (!isAnon)
          PopupMenuItem<String>(
            value: 'settings',
            child: Row(
              children: [
                const Icon(Icons.settings_outlined, size: 20),
                const SizedBox(width: 8),
                const Text('설정'),
              ],
            ),
          ),
        if (isAnon)
          PopupMenuItem<String>(
            value: 'login',
            child: Row(
              children: const [
                Icon(Icons.login, size: 20),
                SizedBox(width: 8),
                Text('로그인'),
              ],
            ),
          ),
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 20, color: Colors.red[300]),
              const SizedBox(width: 8),
              const Text('로그아웃'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return TextButton(
      onPressed: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
      },
      child: const Text('로그인', style: TextStyle(color: Colors.black)),
    );
  }

  void _handleOrdersPress(BuildContext context) {
    AuthUtils.tryWriteWithLoginGuard(context, () async {
      final user = FirebaseAuth.instance.currentUser!;
      await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .get();
      // TODO: 주문 내역 화면 이동
    });
  }
}
