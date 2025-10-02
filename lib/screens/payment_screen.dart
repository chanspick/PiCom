import 'package:flutter/material.dart';
import 'package:picom/models/part_model.dart';

class PaymentScreen extends StatelessWidget {
  final Part part;

  const PaymentScreen({super.key, required this.part});

  @override
  Widget build(BuildContext context) {
    // Using a dummy price for UI/UX purposes
    const dummyPrice = 1200000;

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
            Card(
              elevation: 2,
              child: ListTile(
                title: Text(part.modelName),
                subtitle: Text(part.brand),
                trailing: Text(
                  '${dummyPrice.toStringAsFixed(0)}원',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              '결제 수단',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: ListTile(
                leading: Image.network('https://i.imgur.com/J2llt2s.png', width: 80), // KakaoPay logo
                title: const Text('카카오페이'),
                trailing: const Icon(Icons.check_circle, color: Colors.yellow),
              ),
            ),
            const Spacer(),
            const Center(
              child: Text(
                '실제 결제가 진행되지 않는 테스트 화면입니다.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  // Show a confirmation dialog
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('결제 완료'),
                      content: const Text('결제가 성공적으로 완료되었습니다. (테스트)'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Close dialog
                            Navigator.of(context).pop(); // Go back from payment screen
                          },
                          child: const Text('확인'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('결제하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}