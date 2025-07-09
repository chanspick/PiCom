import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'search_screen.dart';
import 'part_shop_screen.dart';
import 'product_detail_screen.dart';
import '../models/product_model.dart';
import '../widgets/home_app_bar_actions.dart';
import '../widgets/home_search_bar.dart';
import '../widgets/product_price_and_actions.dart';
import '../widgets/banner_item.dart';
import '../widgets/circle_category.dart';

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
        children: [
          _BannerSection(),
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
          const Text('Just Dropped', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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

class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            product.imageUrl,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: ProductPriceAndActions(product: product),
        isThreeLine: true,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(productId: product.id),
            ),
          );
        },
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
          BannerItem(imageUrl: 'https://via.placeholder.com/400x200?text=Event+Banner+1'),
          BannerItem(imageUrl: 'https://via.placeholder.com/400x200?text=New+Arrivals'),
          BannerItem(imageUrl: 'https://via.placeholder.com/400x200?text=Special+Offer'),
        ],
      ),
    );
  }
}

class _CircleMenuSection extends StatelessWidget {
  const _CircleMenuSection();

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> items = [
      {
        'icon': 'https://via.placeholder.com/80?text=Parts',
        'label': '부품 샵',
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PartShopScreen()),
        )
      },
      {
        'icon': 'https://via.placeholder.com/80?text=Brands',
        'label': '브랜드관',
        'onTap': () {/* TODO */}
      },
      {
        'icon': 'https://via.placeholder.com/80?text=Express',
        'label': '빠른 배송',
        'onTap': () {/* TODO */}
      },
      {
        'icon': 'https://via.placeholder.com/80?text=Popular',
        'label': '인기 상품',
        'onTap': () {/* TODO */}
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
            iconUrl: item['icon']!,
            label: item['label']!,
            onTap: item['onTap'] as VoidCallback,
          );
        },
      ),
    );
  }
}
