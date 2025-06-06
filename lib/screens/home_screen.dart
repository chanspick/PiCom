import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// Firestore와 통신하기 위해 cloud_firestore를 import 합니다.
import 'package:cloud_firestore/cloud_firestore.dart';

import 'part_shop_screen.dart';
import 'search_screen.dart';
import '../models/product_model.dart'; // 우리가 사용하는 Product 모델
import 'product_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // [수정 시작] title 부분을 아래 코드로 교체합니다.
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchScreen()),
            );
          },
          // Row와 Expanded로 감싸서 무한 너비 오류를 해결합니다.
          // GestureDetector의 자식 전체에 탭 영역을 주기 위해 Row가 바깥에 위치합니다.
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).splashColor, // 테마에 맞는 색상 사용
                    borderRadius: BorderRadius.circular(30), // 둥근 모양
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.search, color: Colors.grey),
                      SizedBox(width: 8),
                      // 남은 공간을 채우도록 Text에도 Expanded를 적용할 수 있습니다.
                      Expanded(
                        child: Text(
                          '상품을 검색하세요',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // [수정 끝]
        actions: [
          IconButton(
            tooltip: '알림',
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              // TODO: 알림 화면으로 이동
            },
          ),
          IconButton(
            tooltip: '로그아웃',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              // 로그인 화면으로 이동하거나 스낵바 표시 등의 후처리
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('로그아웃 되었습니다.')),
              );
            },
          ),
        ],
      ),
      body: const _HomeContent(), // _HomeContent는 이전에 수정한 그대로 둡니다.
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: const [
          _BannerSection(),
          SizedBox(height: 24),
          _CircleMenuSection(),
          SizedBox(height: 24),
          // 핵심 변경: _ProductListSection이 이제 실시간 데이터를 처리합니다.
          _ProductListSection(),
        ],
      ),
    );
  }
}

// --- 이 아래부터 핵심적인 변경이 이루어집니다 ---

/// **[수정됨]** 상품 목록 섹션 - Firestore 실시간 데이터 연동
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

          // StreamBuilder를 사용하여 Firestore의 'products' 컬렉션을 실시간으로 구독합니다.
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            // 'createdAt' 필드를 기준으로 최신순으로 정렬하고, 상위 10개만 가져옵니다.
            stream: FirebaseFirestore.instance
                .collection('products')
                .orderBy('createdAt', descending: true)
                .limit(10)
                .snapshots(), // .snapshots()이 실시간 업데이트를 가능하게 합니다.
            builder: (context, snapshot) {
              // 로딩 중일 때 로딩 인디케이터를 표시합니다.
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              // 에러가 발생했거나 데이터가 없을 경우 메시지를 표시합니다.
              if (snapshot.hasError) {
                return const Center(child: Text('데이터를 불러오는 중 오류가 발생했습니다.'));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('상품이 없습니다.'));
              }

              // Firestore 문서(docs)를 Product 객체 리스트로 변환합니다.
              final products = snapshot.data!.docs
                  .map((doc) => Product.fromFirestore(doc))
                  .toList();

              // 변환된 product 리스트를 사용하여 UI를 동적으로 생성합니다.
              return ListView.builder(
                shrinkWrap: true, // SingleChildScrollView 안에서 사용하기 위함
                physics: const NeverScrollableScrollPhysics(), // 부모 스크롤 사용
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

/// **[수정됨]** 상품 목록의 개별 카드 - 내비게이션 로직 수정
class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        leading: ClipRRect( /* ... 기존 UI 코드와 동일 ... */ ),
        title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Column( /* ... 기존 UI 코드와 동일 ... */ ),
        isThreeLine: true,
        onTap: () {
          // [중요] ProductDetailScreen으로 이동할 때, product 객체 전체가 아닌
          // product.id 값을 'productId' 파라미터로 전달합니다.
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


// --- 하위 위젯들 ---
/// 상단 배너 광고 섹션
class _BannerSection extends StatelessWidget {
  const _BannerSection();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: PageView(
        children: const [
          _BannerItem(imageUrl: 'https://via.placeholder.com/400x200?text=Event+Banner+1'),
          _BannerItem(imageUrl: 'https://via.placeholder.com/400x200?text=New+Arrivals'),
          _BannerItem(imageUrl: 'https://via.placeholder.com/400x200?text=Special+Offer'),
        ],
      ),
    );
  }
}
class _BannerItem extends StatelessWidget {
  final String imageUrl;
  const _BannerItem({required this.imageUrl});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(imageUrl, fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.grey[300],
            alignment: Alignment.center,
            child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}

/// 동그란 아이콘 메뉴 섹션
class _CircleMenuSection extends StatelessWidget {
  const _CircleMenuSection();

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> items = [
      {'icon': 'https://via.placeholder.com/80?text=Parts', 'label': '부품 샵', 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PartShopScreen()))},
      {'icon': 'https://via.placeholder.com/80?text=Brands', 'label': '브랜드관', 'onTap': () { /* TODO */ }},
      {'icon': 'https://via.placeholder.com/80?text=Express', 'label': '빠른 배송', 'onTap': () { /* TODO */ }},
      {'icon': 'https://via.placeholder.com/80?text=Popular', 'label': '인기 상품', 'onTap': () { /* TODO */ }},
    ];

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _CircleCategory(iconUrl: item['icon']!, label: item['label']!, onTap: item['onTap'] as VoidCallback);
        },
      ),
    );
  }
}
class _CircleCategory extends StatelessWidget {
  final String iconUrl;
  final String label;
  final VoidCallback onTap;
  const _CircleCategory({required this.iconUrl, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        color: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(radius: 30, backgroundImage: NetworkImage(iconUrl), backgroundColor: Colors.grey[200]),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}