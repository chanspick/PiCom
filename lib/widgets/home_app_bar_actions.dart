import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/auth_screen.dart';
import '../utils/auth_utils.dart';

class HomeAppBarActions extends StatelessWidget {
  const HomeAppBarActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: '알림',
          icon: const Icon(Icons.notifications_none),
          onPressed: () => _handleNotificationPress(context),
        ),
        IconButton(
          tooltip: '장바구니',
          icon: const Icon(Icons.shopping_cart_outlined),
          onPressed: () => _handleCartPress(context),
        ),
        StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.hasData && !snapshot.data!.isAnonymous) {
              return _buildUserMenu(context, snapshot.data!);
            } else {
              return _buildLoginButton(context);
            }
          },
        ),
      ],
    );
  }

  void _handleNotificationPress(BuildContext context) {
    // 1차 인증 체크
    if (!AuthUtils.requireAuth(context)) {
      return;
    }

    // 알림 읽기 시도 (Firestore에서 알림 데이터 가져오기)
    AuthUtils.tryWriteWithLoginGuard(context, () async {
      final user = FirebaseAuth.instance.currentUser!;

      // 알림 읽음 상태 업데이트 (쓰기 권한 필요)
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

      // TODO: 알림 화면으로 이동
    });
  }

  void _handleCartPress(BuildContext context) {
    // 1차 인증 체크
    if (!AuthUtils.requireAuth(context)) {
      return;
    }

    // 장바구니 접근 시도
    AuthUtils.tryWriteWithLoginGuard(context, () async {
      final user = FirebaseAuth.instance.currentUser!;

      // 장바구니에 상품 추가나 수정 시 쓰기 권한 필요
      // 여기서는 장바구니 접근만 시뮬레이션
      await FirebaseFirestore.instance
          .collection('cart')
          .where('userId', isEqualTo: user.uid)
          .get();

      // TODO: 장바구니 화면으로 이동
    });
  }

  Widget _buildUserMenu(BuildContext context, User user) {
    return PopupMenuButton<String>(
      tooltip: '사용자 메뉴',
      icon: const Icon(Icons.account_circle),
      onSelected: (value) async {
        switch (value) {
          case 'profile':
          // TODO: 프로필 화면으로 이동
            break;
          case 'orders':
            _handleOrdersPress(context);
            break;
          case 'logout':
            await FirebaseAuth.instance.signOut();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('로그아웃 되었습니다.')),
              );
            }
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'profile',
          child: Row(
            children: [
              const Icon(Icons.person, size: 20),
              const SizedBox(width: 8),
              Text(user.displayName ?? '내 정보'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'orders',
          child: Row(
            children: [
              Icon(Icons.receipt_long, size: 20),
              SizedBox(width: 8),
              Text('주문 내역'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 20),
              SizedBox(width: 8),
              Text('로그아웃'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AuthScreen()),
        );
      },
      child: const Text(
        '로그인',
        style: TextStyle(color: Colors.black),
      ),
    );
  }

  void _handleOrdersPress(BuildContext context) {
    // 주문 내역 조회
    AuthUtils.tryWriteWithLoginGuard(context, () async {
      final user = FirebaseAuth.instance.currentUser!;

      // 주문 내역 조회는 읽기지만, 상태 업데이트 등이 필요할 수 있음
      await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .get();

      // TODO: 주문 내역 화면으로 이동
    });
  }
}
