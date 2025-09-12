
import 'package:flutter/material.dart';

class DeliveryStatusScreen extends StatelessWidget {
  const DeliveryStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('배송 현황'),
      ),
      body: const Center(
        child: Text('배송 현황을 조회하는 페이지입니다.'),
      ),
    );
  }
}
