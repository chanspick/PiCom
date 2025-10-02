import 'package:flutter/material.dart';

class MyComputerScreen extends StatelessWidget {
  const MyComputerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('나만의 컴퓨터'),
      ),
      body: const Center(
        child: Text('나만의 컴퓨터 페이지입니다.'),
      ),
    );
  }
}
