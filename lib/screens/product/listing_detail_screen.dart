// lib/screens/product/listing_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/listing_model.dart';
import '../../models/part_model.dart';
import '../../models/cart_item_model.dart'; // [추가] CartItem 모델 import
import '../../services/listing_service.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../payment_screen.dart'; // [추가] PaymentScreen import

class ListingDetailScreen extends StatefulWidget {
  final String listingId;

  const ListingDetailScreen({super.key, required this.listingId});

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  // [수정] 클래스 멤버 변수들을 build 메소드 위로 이동
  final ListingService _listingService = ListingService();
  final OrderService _orderService = OrderService();
  final AuthService _authService = AuthService();
  bool _isPurchasing = false;

  Future<void> _purchaseItem(Listing listing) async {
    if (!_authService.requireAuth(context)) return;

    if (_authService.currentUser?.uid == listing.sellerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('자신의 판매 상품은 구매할 수 없습니다.')),
      );
      return;
    }

    final singleCartItem = CartItem(
      productId: listing.listingId,
      productName: listing.modelName,
      price: listing.price.toDouble(),
      quantity: 1,
      imageUrl: listing.imageUrls.isNotEmpty ? listing.imageUrls.first : '',
      addedAt: Timestamp.now(),
    );

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentScreen(cartItems: [singleCartItem]),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Listing>(
      stream: _listingService.getListing(widget.listingId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: Text('상품 정보를 불러올 수 없습니다.')));
        }

        final listing = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: const BackButton(color: Colors.black),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined, color: Colors.black),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.favorite_border, color: Colors.black),
                onPressed: () {},
              ),
            ],
          ),
          body: FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('parts').doc(listing.partId).get(),
            builder: (context, partSnapshot) {
              if (!partSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final part = Part.fromFirestore(partSnapshot.data!);

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImageCarousel(listing.imageUrls),
                    _buildHeader(listing, part),
                    _buildPriceInfo(listing),
                    _buildSectionDivider(),
                  ],
                ),
              );
            },
          ),
          bottomNavigationBar: _buildBottomPurchaseBar(context, listing),
        );
      },
    );
  }

  Widget _buildImageCarousel(List<String> imageUrls) {
    return SizedBox(
      height: MediaQuery.of(context).size.width,
      child: PageView.builder(
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return CachedNetworkImage(
            imageUrl: imageUrls[index],
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(color: Colors.grey[200]),
            errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
          );
        },
      ),
    );
  }

  Widget _buildHeader(Listing listing, Part part) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            part.brand,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(part.modelName, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            '컨디션: ${listing.conditionScore}',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceInfo(Listing listing) {
    final formatter = NumberFormat('#,###');
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '판매 가격',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            '${formatter.format(listing.price)}원',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionDivider() => Divider(thickness: 8, color: Colors.grey[100]);

  Widget _buildBottomPurchaseBar(BuildContext context, Listing listing) {
    final bool isSold = listing.status == ListingStatus.sold;
    final bool isMyItem = _authService.currentUser?.uid == listing.sellerId;
    final bool canPurchase = !isSold && !isMyItem;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: canPurchase ? Colors.red : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: (canPurchase && !_isPurchasing) ? () => _purchaseItem(listing) : null,
              child: _isPurchasing
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0),
              )
                  : Text(isSold ? '판매 완료' : (isMyItem ? '내 판매 상품' : '구매하기')),
            ),
          ),
        ],
      ),
    );
  }
} // [수정] 클래스의 닫는 중괄호를 파일의 맨 끝으로 이동