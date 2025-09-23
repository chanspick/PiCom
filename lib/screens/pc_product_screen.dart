import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:picom/models/pc_product_model.dart';
import 'package:picom/services/firestore_service.dart';
import 'package:picom/widgets/product_card.dart';

class PCProductScreen extends StatefulWidget {
  const PCProductScreen({super.key});

  @override
  State<PCProductScreen> createState() => _PCProductScreenState();
}

class _PCProductScreenState extends State<PCProductScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String _selectedCategory = 'All';
  String _selectedSort = '인기순';

  final List<DropdownMenuItem<String>> _categoryItems = ['All', '게임용', '개발용', '사무용', '올인원']
      .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
      .toList();

  final List<DropdownMenuItem<String>> _sortItems = ['인기순', '최신순', '낮은 가격순', '높은 가격순', '성능순']
      .map((sort) => DropdownMenuItem(value: sort, child: Text(sort)))
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PC 완제품'),
      ),
      body: Column(
        children: [
          _buildFilterRow(),
          Expanded(
            child: StreamBuilder<List<PCProduct>>(
              stream: _firestoreService.getPCProducts(
                category: _selectedCategory,
                sortBy: _selectedSort,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('오류: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('제품이 없습니다.'));
                }

                final products = snapshot.data!;
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
                    final product = products[index];
                    final formatter = NumberFormat('#,###');
                    return ProductCard(
                      imageUrl: product.imageUrl,
                      name: product.name,
                      priceText: '${formatter.format(product.price)} 원',
                      onTap: () {
                        // TODO: Navigate to PC Product Detail Screen
                      },
                    );
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
          // Category Filter (Left)
          Expanded(
            child: DropdownButton<String>(
              value: _selectedCategory,
              isExpanded: true,
              underline: const SizedBox(),
              items: _categoryItems,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCategory = value);
                }
              },
            ),
          ),
          const VerticalDivider(width: 20),
          // Sort Filter (Right)
          Expanded(
            child: DropdownButton<String>(
              value: _selectedSort,
              isExpanded: true,
              underline: const SizedBox(),
              items: _sortItems,
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