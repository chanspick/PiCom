// lib/screens/payment_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../models/cart_item_model.dart';
import '../services/order_service.dart';

class PaymentScreen extends StatefulWidget {
  final List<CartItem> cartItems;

  const PaymentScreen({super.key, required this.cartItems});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final OrderService _orderService = OrderService();
  bool _isLoading = false;

  double get _totalPrice {
    // [수정] CartItem 모델에 quantity가 없으므로 price만 합산합니다.
    // 중고 부품은 모두 수량이 1개입니다.
    return widget.cartItems.fold(0, (total, current) => total + current.price);
  }

  // [수정] 새로운 createOrder 함수를 호출하도록 로직 변경
  Future<void> _processPayment() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("로그인이 필요합니다.");
      }

      // 1. CartItem 리스트에서 listingId(productId) 리스트를 추출합니다.
      final listingIds = widget.cartItems.map((item) => item.productId).toList();

      // 2. TODO: 실제 배송지 정보를 사용자로부터 입력받아야 합니다. 현재는 임시값을 사용합니다.
      final tempShippingAddress = {
        'recipientName': '홍길동',
        'address': '서울시 강남구 테헤란로',
        'phoneNumber': '010-1234-5678',
      };

      // 3. [핵심 수정] 새로운 createOrder 함수를 호출합니다.
      await _orderService.createOrder(
        listingIds: listingIds,
        isBundle: false, // 장바구니 구매는 조립(번들)이 아님
        shippingAddress: tempShippingAddress,
      );

      // Show success dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('주문 완료'),
            content: const Text('주문이 성공적으로 완료되었습니다.'),
            actions: [
              TextButton(
                onPressed: () {
                  // TODO: 장바구니 비우기 로직 호출 필요
                  // cartService.clearCart();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (이하 UI 관련 코드는 기존과 거의 동일) ...
    final formatter = NumberFormat('#,###');

    return Scaffold(
      appBar: AppBar(
        title: const Text('결제 요청'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '주문 상품 정보',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: widget.cartItems.length,
                itemBuilder: (context, index) {
                  final item = widget.cartItems[index];
                  return Card(
                    elevation: 1,
                    child: ListTile(
                      leading: item.imageUrl.isNotEmpty
                          ? Image.network(item.imageUrl, width: 50, height: 50, fit: BoxFit.cover)
                          : const Icon(Icons.image, size: 50),
                      title: Text(item.productName),
                      // [수정] 중고품은 수량이 1이므로 subtitle 불필요 시 제거 가능
                      subtitle: const Text('수량: 1'),
                      trailing: Text('${formatter.format(item.price)}원'),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '결제 수단',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 1,
              child: ListTile(
                leading: Image.network('https://i.imgur.com/J2llt2s.png', width: 80), // KakaoPay logo
                title: const Text('카카오페이'),
                trailing: const Icon(Icons.check_circle, color: Colors.amber),
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '총 결제 금액',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${formatter.format(_totalPrice)}원',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.redAccent),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _processPayment,
                child: _isLoading
                    ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 3, color: Colors.black),
                )
                    : const Text('결제하기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}