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
    return widget.cartItems.fold(0, (total, current) => total + (current.price * current.quantity));
  }

  Future<void> _processPayment() async {
    if (_isLoading) return; // Prevent double-taps

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("로그인이 필요합니다.");
      }

      // Call the order creation service
      await _orderService.createOrders(
        buyerId: user.uid,
        cartItems: widget.cartItems,
      );

      // Show success dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false, // User must tap button
          builder: (context) => AlertDialog(
            title: const Text('주문 완료'),
            content: const Text('주문이 성공적으로 완료되었습니다.'),
            actions: [
              TextButton(
                onPressed: () {
                  // Pop all screens until the first one (usually home)
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Show error dialog
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
                      subtitle: Text('수량: ${item.quantity}'),
                      trailing: Text('${formatter.format(item.price * item.quantity)}원'),
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
                onPressed: _isLoading ? null : _processPayment, // Disable button when loading
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