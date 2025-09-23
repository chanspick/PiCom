import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/listing_model.dart';
import '../../models/part_model.dart';
import '../../services/listing_service.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';

class ListingDetailScreen extends StatefulWidget {
  final String listingId;

  const ListingDetailScreen({super.key, required this.listingId});

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  final ListingService _listingService = ListingService();
  final OrderService _orderService = OrderService();
  final AuthService _authService = AuthService();
  bool _isPurchasing = false;

  Future<void> _purchaseItem(Listing listing) async {
    if (!_authService.requireAuth(context)) return;

    // Prevent user from buying their own item
    if (_authService.currentUser?.uid == listing.sellerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('자신의 판매 상품은 구매할 수 없습니다.')),
      );
      return;
    }

    setState(() => _isPurchasing = true);

    try {
      await _orderService.purchaseListing(widget.listingId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('상품을 성공적으로 구매했습니다!')),
        );
        Navigator.of(context).pop(); // Go back to the list view
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('구매 중 오류가 발생했습니다: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPurchasing = false);
      }
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
                    _buildDescription('판매자 코멘트', listing.description),
                    _buildSectionDivider(),
                    _buildSpecs(part),
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
      height: MediaQuery.of(context).size.width, // Square aspect ratio
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
          Text(part.name, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            '컨디션: ${listing.condition}',
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

  Widget _buildDescription(String title, String content) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 16, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildSpecs(Part part) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('주요 사양', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (part.specs.isNotEmpty)
            ...part.specs.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Row(
                    children: [
                      SizedBox(width: 100, child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(child: Text(entry.value.toString())),
                    ],
                  ),
                ))
          else
            const Text('등록된 사양 정보가 없습니다.'),
        ],
      ),
    );
  }

  Widget _buildSectionDivider() => Divider(thickness: 8, color: Colors.grey[100]);

  Widget _buildBottomPurchaseBar(BuildContext context, Listing listing) {
    final bool isSold = listing.status == 'sold';
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
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(isSold ? '판매 완료' : (isMyItem ? '내 판매 상품' : '구매하기')),
            ),
          ),
        ],
      ),
    );
  }
}