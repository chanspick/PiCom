import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart';
import '../widgets/price_history_chart.dart';
import '../widgets/bid_dialog.dart';
import '../utils/auth_utils.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data?.data() == null) {
          return const Scaffold(body: Center(child: Text('상품 정보를 불러올 수 없습니다.')));
        }

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
                _ProductHeader(product: product),
                const Divider(),
                _PriceInfo(product: product),
                const Divider(),
                PriceHistoryChart(
                  priceHistory: product.priceHistory,
                  currentPrice: product.lastTradedPrice,
                ),
                // 추가 정보 섹션 등
              ],
            ),
          ),
          bottomNavigationBar: _TradeButtons(product: product),
        );
      },
    );
  }
}

class _ProductHeader extends StatelessWidget {
  final Product product;
  const _ProductHeader({required this.product});

  @override
  Widget build(BuildContext context) {
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
                child: const Center(child: Icon(Icons.broken_image, size: 50)),
              ),
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
}

class _PriceInfo extends StatelessWidget {
  final Product product;
  const _PriceInfo({required this.product});

  @override
  Widget build(BuildContext context) {
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
}

class _TradeButtons extends StatelessWidget {
  final Product product;
  const _TradeButtons({required this.product});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _handleTrade(context, isBuy: false),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('판매', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                  Text('${formatter.format(product.highestBid)}원', style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _handleTrade(context, isBuy: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('구매', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                  Text('${formatter.format(product.lowestAsk)}원', style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleTrade(BuildContext context, {required bool isBuy}) {
    // 인증 체크: 익명/미로그인 시 로그인 창으로 이동
    if (!AuthUtils.requireAuth(context)) return;

    // 정규 로그인 상태일 때만 입찰 다이얼로그 표시
    showDialog(
      context: context,
      builder: (context) => BidDialog(product: product, isBuy: isBuy),
    );
  }
}
