
import 'package:flutter/material.dart';

class BrandHallScreen extends StatelessWidget {
  const BrandHallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('브랜드관'),
      ),
      body: const Center(
        child: Text('브랜드관 페이지입니다.'),
      ),
    );
  }
}
