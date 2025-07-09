import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/product_model.dart';
import '../utils/auth_utils.dart';

class ProductPriceAndActions extends StatelessWidget {
  final Product product;

  const ProductPriceAndActions({
    required this.product,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${formatter.format(product.lastTradedPrice)}원',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _handleBuyPress(context),
                child: const Text('구매'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _handleSellPress(context),
                child: const Text('판매'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _handleBuyPress(BuildContext context) {
    // 1차 인증 체크 - 미리 확인하여 불필요한 Firestore 요청 방지
    if (!AuthUtils.requireAuth(context)) {
      return;
    }

    // 2차 Firestore 쓰기 시도 - 권한 오류 시 자동 로그인 유도
    AuthUtils.tryWriteWithLoginGuard(context, () async {
      final user = FirebaseAuth.instance.currentUser!;

      // 구매 주문 생성
      await FirebaseFirestore.instance.collection('orders').add({
        'productId': product.id,
        'userId': user.uid,
        'type': 'buy',
        'price': product.lowestAsk,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 성공 메시지
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('구매 주문이 접수되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  void _handleSellPress(BuildContext context) {
    // 1차 인증 체크
    if (!AuthUtils.requireAuth(context)) {
      return;
    }

    // 2차 Firestore 쓰기 시도
    AuthUtils.tryWriteWithLoginGuard(context, () async {
      final user = FirebaseAuth.instance.currentUser!;

      // 판매 주문 생성
      await FirebaseFirestore.instance.collection('asks').add({
        'productId': product.id,
        'userId': user.uid,
        'type': 'sell',
        'price': product.highestBid,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 성공 메시지
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('판매 주문이 접수되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }
}
