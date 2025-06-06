import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
// 만들어 둔 Product 모델과 ProductDetailScreen을 import 합니다.
import '../models/product_model.dart';
import 'product_detail_screen.dart';

class PartShopScreen extends StatefulWidget {
  const PartShopScreen({super.key});

  @override
  State<PartShopScreen> createState() => _PartShopScreenState();
}

class _PartShopScreenState extends State<PartShopScreen> {
  String _selectedCategory = 'All';
  String _selectedSort = '인기순'; // 정렬 기준: 인기순, 최신순, 낮은 가격순, 높은 가격순

  // Firestore 쿼리를 동적으로 생성하는 함수
  Query<Map<String, dynamic>> _buildQuery() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('products');

    // 카테고리 필터링
    if (_selectedCategory != 'All') {
      // Firestore에서는 'brand' 필드를 카테고리처럼 사용하기로 했습니다.
      query = query.where('brand', isEqualTo: _selectedCategory);
    }

    // 정렬 조건
    switch (_selectedSort) {
      case '최신순':
      // 'createdAt' 같은 필드가 Firestore 문서에 있어야 합니다.
        query = query.orderBy('createdAt', descending: true);
        break;
      case '낮은 가격순':
        query = query.orderBy('lowestAsk', descending: false);
        break;
      case '높은 가격순':
        query = query.orderBy('lowestAsk', descending: true);
        break;
      case '인기순':
      default:
      // 'likes' 같은 필드가 Firestore 문서에 있어야 합니다.
        query = query.orderBy('likes', descending: true);
        break;
    }

    return query;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('부품 스토어'),
        // TODO: 고급 필터 기능 구현
        actions: [IconButton(icon: const Icon(Icons.tune), onPressed: () {})],
      ),
      body: Column(
        children: [
          _buildFilterRow(),
          Expanded(
            // FutureBuilder를 사용하여 Firestore 쿼리 결과를 비동기적으로 처리
            child: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
              future: _buildQuery().get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('오류가 발생했습니다: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('해당하는 상품이 없습니다.'));
                }

                // Firestore 문서들을 Product 객체 리스트로 변환
                final products = snapshot.data!.docs
                    .map((doc) => Product.fromFirestore(doc))
                    .toList();

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7, // 아이템 비율
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return _buildProductItem(products[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 필터 및 정렬 UI
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
              items: ['All', 'CPU', 'GPU', 'RAM', 'SSD', 'Cooler']
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedCategory = value);
              },
            ),
          ),
          const VerticalDivider(width: 20),
          Expanded(
            child: DropdownButton<String>(
              value: _selectedSort,
              isExpanded: true,
              underline: const SizedBox(),
              items: ['인기순', '최신순', '낮은 가격순', '높은 가격순']
                  .map((sort) => DropdownMenuItem(value: sort, child: Text(sort)))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedSort = value);
              },
            ),
          ),
        ],
      ),
    );
  }

  // 개별 상품 카드 UI
  Widget _buildProductItem(Product product) {
    final formatter = NumberFormat('#,###');

    return GestureDetector(
      onTap: () {
        // ProductDetailScreen으로 이동, 이제 Product 객체 대신 productId를 전달합니다.
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => ProductDetailScreen(productId: product.id),
        ));
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 2, blurRadius: 6),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(product.imageUrl, fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${formatter.format(product.lowestAsk ?? 0)} 원~', // 즉시 구매가 표시
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
