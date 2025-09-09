import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/product_model.dart';
import 'product_detail_screen.dart';

class PartShopScreen extends StatefulWidget {
  const PartShopScreen({super.key});

  @override
  State<PartShopScreen> createState() => _PartShopScreenState();
}

class _PartShopScreenState extends State<PartShopScreen> {
  String _selectedCategory = 'All';
  String _selectedSort = '인기순';

  Query<Map<String, dynamic>> _buildQuery() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('products');

    if (_selectedCategory != 'All') {
      query = query.where('brand', isEqualTo: _selectedCategory);
    }

    switch (_selectedSort) {
      case '최신순':
        query = query.orderBy('createdAt', descending: true);
        break;
      case '낮은 가격순':
        query = query.orderBy('lastTradedPrice', descending: false);
        break;
      case '높은 가격순':
        query = query.orderBy('lastTradedPrice', descending: true);
        break;
      case '인기순':
      default:
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
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () {
              // TODO: 고급 필터 기능 구현
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterRow(),
          Expanded(
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

                final products = snapshot.data!.docs
                    .map((doc) => Product.fromFirestore(doc))
                    .toList();

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
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

  Widget _buildProductItem(Product product) {
    final formatter = NumberFormat('#,###');

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => ProductDetailScreen(productId: product.id),
        ));
      },
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  product.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
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
                    Expanded(
                      child: Text(
                        product.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.lastTradedPrice > 0 
                          ? '${formatter.format(product.lastTradedPrice)} 원'
                          : '거래 내역 없음',
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
