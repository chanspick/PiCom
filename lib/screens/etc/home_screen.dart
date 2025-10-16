import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/listing_model.dart';
import '../../services/listing_service.dart';
import '../product/listing_detail_screen.dart';
import '../product/parts_category_screen.dart';
import '../product/sell_request_screen.dart';
import '../../widgets/home_app_bar_actions.dart';
import '../../widgets/home_search_bar.dart';
import '../../widgets/home_banner.dart';
import '../../widgets/circle_category.dart';
import '../community/community_screen.dart';
import '../pc_assembly_screen.dart';
import '../product/part_shop_screen.dart';
import '../selling/finished_pc_sell_screen.dart';

import 'part_name.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const HomeSearchBar(),
        actions: const [HomeAppBarActions()],
      ),
      body: const _HomeContent(),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HomeBanner(),
          SizedBox(height: 24),
          _CircleMenuSection(),
          SizedBox(height: 24),
          _ProductListSection(),
        ],
      ),
    );
  }
}

class _ProductListSection extends StatelessWidget {
  const _ProductListSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '최신 상품',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<Listing>>(
            stream: ListingService().getLatestListings(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('데이터를 불러오는 중 오류가 발생했습니다: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('상품이 없습니다.'));
              }

              final listings = snapshot.data!;

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: listings.length,
                itemBuilder: (context, index) {
                  return _ListingCard(listing: listings[index]);
                },
              );
            },
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
    return Container(
      height: 120,
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ListingDetailScreen(listingId: listing.listingId),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: listing.imageUrls.isNotEmpty ? listing.imageUrls.first : '',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey[200]),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.broken_image,
                        size: 40,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 48,
                        child: PartName(partId: listing.partId),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${listing.price.toStringAsFixed(0)}원',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF42A5F5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleMenuSection extends StatelessWidget {
  const _CircleMenuSection();

  static final _menuItems = [
    {
      'icon': Icons.settings,
      'label': '부품 샵',
      'screen': const PartShopScreen(),
    },
    {
      'icon': Icons.store,
      'label': '부품 시세',
      'screen': PartsCategoryScreen(),
    },
    {
      'icon': Icons.desktop_mac,
      'label': '나만의 컴퓨터',
      'screen': const PcAssemblyScreen(),
    },
    {
      'icon': Icons.add_box_outlined,
      'label': '부품 판매',
      'screen': const SellRequestScreen(),
    },
    {
      'icon': Icons.desktop_windows,
      'label': '완제품 판매',
      'screen': const FinishedPcSellScreen(), // <-- 새로 만들 화면으로 연결
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _menuItems.length,
        itemBuilder: (context, index) {
          final item = _menuItems[index];
          return CircleCategory(
            iconData: item['icon']! as IconData,
            label: item['label']! as String,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => item['screen'] as Widget),
            ),
          );
        },
      ),
    );
  }
}