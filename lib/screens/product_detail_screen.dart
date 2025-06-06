import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart'; // Product 모델 import
import '../widgets/price_history_chart.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId; // Product 객체 대신 productId를 받습니다.

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  // StreamBuilder를 사용하여 Firestore의 상품 데이터를 실시간으로 수신합니다.
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data?.data() == null) {
          return const Scaffold(
            body: Center(child: Text('상품 정보를 불러올 수 없습니다.')),
          );
        }

        // Firestore 문서로부터 Product 객체를 생성합니다.
        final product = Product.fromFirestore(snapshot.data!);

        return Scaffold(
          appBar: AppBar(
            title: Text(product.brand),
            actions: [
              IconButton(icon: const Icon(Icons.favorite_border), onPressed: () {}),
              IconButton(icon: const Icon(Icons.share), onPressed: () {}),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProductHeader(product),
                const Divider(),
                _buildPriceInfo(context, product),
                const Divider(),
                _buildPriceChart(product),
                // 여기에 추가 정보 섹션을 넣을 수 있습니다.
              ],
            ),
          ),
          bottomNavigationBar: _buildTradeButtons(context, product),
        );
      },
    );
  }

  // 위젯 함수들은 이제 product를 인자로 받습니다.
  Widget _buildProductHeader(Product product) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Image.network(
              product.imageUrl,
              height: 250,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                  height: 250,
                  color: Colors.grey[200],
                  child: const Center(child: Icon(Icons.broken_image, size: 50))),
            ),
          ),
          const SizedBox(height: 16),
          Text(product.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(product.modelCode, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildPriceInfo(BuildContext context, Product product) {
    final formatter = NumberFormat('#,###');
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          const Text('최근 거래가', style: TextStyle(fontSize: 16)),
          const Spacer(),
          Text(
            '${formatter.format(product.lastTradedPrice)}원',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceChart(Product product) {
    return PriceHistoryChart(
      priceHistory: product.priceHistory,
      currentPrice: product.lastTradedPrice, // 현재 최근 거래가 전달
    );
  }

  Widget _buildTradeButtons(BuildContext context, Product product) {
    final formatter = NumberFormat('#,###');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _showBidDialog(context, product: product, isBuy: false),
              // [핵심 수정] 버튼 스타일을 적용합니다.
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: const StadiumBorder(), // 양 끝이 완전히 둥근 모양
                elevation: 0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                      const Text('판매', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(
                    '${formatter.format(product.highestBid)}원',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _showBidDialog(context, product: product, isBuy: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: const StadiumBorder(), // 양 끝이 완전히 둥근 모양
                elevation: 0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('구매', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(
                    '${formatter.format(product.lowestAsk)}원',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  // 구매/판매 입찰을 위한 다이얼로그 표시 함수
  void _showBidDialog(BuildContext context, {required Product product, required bool isBuy}) {
    final priceController = TextEditingController();
    final title = isBuy ? '구매 입찰' : '판매 입찰';
    final collectionName = isBuy ? 'bids' : 'asks';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: '희망가 (원)'),
          ),
          actions: [
            TextButton(child: const Text('취소'), onPressed: () => Navigator.of(context).pop()),
            ElevatedButton(
              child: const Text('입찰 등록'),
              onPressed: () async {
                final price = double.tryParse(priceController.text);
                final user = FirebaseAuth.instance.currentUser;

                if (user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
                  return;
                }
                if (price == null || price <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('유효한 가격을 입력해주세요.')));
                  return;
                }

                // 클라이언트는 'asks' 또는 'bids' 컬렉션에 입찰 문서만 생성합니다.
                await FirebaseFirestore.instance.collection(collectionName).add({
                  'productId': product.id,
                  'userId': user.uid,
                  'price': price,
                  'createdAt': FieldValue.serverTimestamp(),
                  'status': 'active', // 입찰 상태
                });

                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('입찰이 등록되었습니다.')));
              },
            ),
          ],
        );
      },
    );
  }
}
