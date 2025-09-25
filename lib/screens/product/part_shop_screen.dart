import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/part_model.dart';
import '../../models/listing_model.dart';
import '../../services/listing_service.dart';
import 'listing_detail_screen.dart';


class PartShopScreen extends StatefulWidget {
  const PartShopScreen({super.key});

  @override
  State<PartShopScreen> createState() => _PartShopScreenState();
}

class _PartShopScreenState extends State<PartShopScreen> {
  final ListingService _listingService = ListingService();
  String _selectedCategory = 'All';
  String _selectedSort = '최신순';

  final List<String> _categories = ['All', 'CPU', 'GPU', 'RAM', '메인보드', '저장장치', '기타'];
  final List<String> _sortOptions = ['최신순', '낮은 가격순', '높은 가격순'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('부품 스토어'),
      ),
      body: Column(
        children: [
          _buildFilterRow(),
          Expanded(
            child: StreamBuilder<List<Listing>>(
              stream: _listingService.getListings(
                category: _selectedCategory,
                sortBy: _selectedSort,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('오류가 발생했습니다: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('판매중인 상품이 없습니다.'));
                }

                final listings = snapshot.data!;

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: listings.length,
                  itemBuilder: (context, index) {
                    final listing = listings[index];
                    return _ListingCard(listing: listing);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: DropdownButton<String>(
              value: _selectedCategory,
              isExpanded: true,
              underline: const SizedBox(),
              items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCategory = value);
                }
              },
            ),
          ),
          const VerticalDivider(width: 20),
          Expanded(
            child: DropdownButton<String>(
              value: _selectedSort,
              isExpanded: true,
              underline: const SizedBox(),
              items: _sortOptions.map((sort) => DropdownMenuItem(value: sort, child: Text(sort))).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedSort = value);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  final Listing listing;

  const _ListingCard({required this.listing});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 6,
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ListingDetailScreen(listingId: listing.listingId), // Changed from listing.id to listing.listingId
          ));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: CachedNetworkImage(
                  imageUrl: listing.imageUrls.isNotEmpty ? listing.imageUrls.first : '',
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey[200]),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.brand,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance.collection('parts').doc(listing.partId).get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Text('...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14));
                          }
                          if (!snapshot.hasData || !snapshot.data!.exists) {
                            return const Text('부품 정보 없음', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14));
                          }
                          final part = Part.fromFirestore(snapshot.data!);
                          return Text(
                            part.modelName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${formatter.format(listing.price)}원',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}