import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'part_shop_screen.dart';
import 'product_detail_screen.dart';
import '../models/product_model.dart';
import '../widgets/home_app_bar_actions.dart';
import '../widgets/home_search_bar.dart';
import '../widgets/product_price_and_actions.dart';
import '../widgets/banner_item.dart';
import '../widgets/circle_category.dart';
import '../screens/gemini_community_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const HomeSearchBar(),
        actions: [HomeAppBarActions()],
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
          _BannerSection(),
          SizedBox(height: 16),
          const SizedBox(height: 24),
          _CircleMenuSection(),
          SizedBox(height: 24),
          _ProductListSection(),
        ],
      ),
    );
  }
}

class _CommunityBanner extends StatelessWidget {
  const _CommunityBanner();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const GeminiCommunityScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.deepPurple[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.deepPurple[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.forum_rounded, color: Colors.deepPurple, size: 40),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI 커뮤니티에 참여하세요',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.deepPurple,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Gemini와 함께하는 새로운 소통 공간',
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.deepPurple),
          ],
        ),
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
            'Just Dropped',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('products')
                .orderBy('createdAt', descending: true)
                .limit(10)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('데이터를 불러오는 중 오류가 발생했습니다.'));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('상품이 없습니다.'));
              }

              final products = snapshot.data!.docs
                  .map((doc) => Product.fromFirestore(doc))
                  .toList();

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  return _ProductCard(product: products[index]);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

// 핵심: 완전히 수정된 ProductCard
class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      // 고정 높이로 모든 카드 크기 통일
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
                    ProductDetailScreen(productId: product.id),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 상품 이미지 (고정 크기)
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      product.imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.broken_image,
                        size: 40,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // 상품 정보 (Expanded로 남은 공간 모두 차지)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 상품명 (반드시 한 줄)
                      SizedBox(
                        height: 24, // 텍스트 높이 고정
                        child: Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // 가격 (고정 높이)
                      ProductPriceAndActions(product: product),
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

class _BannerSection extends StatelessWidget {
  const _BannerSection();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: PageView(
        children: const [
          BannerItem(imageUrl: 'https://via.placeholder.com/800x400.png/007BFF/FFFFFF?text=PiCom+%EC%95%B1+%ED%99%8d%EB%B3%B4'),
          BannerItem(imageUrl: 'https://via.placeholder.com/800x400.png/28A745/FFFFFF?text=%EA%B3%A0%EA%B0%9D+%EB%AC%B8%EC%9D%98'),
          BannerItem(imageUrl: 'https://via.placeholder.com/800x400.png/FFC107/000000?text=%EC%9D%B8%EA%B8%B0+%EC%83%81%ED%92%88'),
        ],
      ),
    );
  }
}

class _CircleMenuSection extends StatelessWidget {
  const _CircleMenuSection();

  @override
  Widget build(BuildContext context) {
    final items = [
      {
        'icon': Icons.settings,
        'label': '부품 샵',
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PartShopScreen()),
        ),
      },
      {
        'icon': Icons.store,
        'label': '브랜드관',
        'onTap': () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('브랜드관 준비 중입니다.')));
        },
      },
      {
        'icon': Icons.forum,
        'label': '커뮤니티',
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const GeminiCommunityScreen()),
        ),
      },
      {
        'icon': Icons.trending_up,
        'label': '인기 상품',
        'onTap': () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('인기 상품 리스트 준비 중입니다.')));
        },
      },
    ];

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return CircleCategory(
            iconData: item['icon']! as IconData,
            label: item['label']! as String,
            onTap: item['onTap'] as VoidCallback,
          );
        },
      ),
    );
  }
}
