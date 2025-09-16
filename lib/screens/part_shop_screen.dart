import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../models/product_model.dart';
import '../screens/product_detail_screen.dart';

class PartShopScreen extends StatefulWidget {
  const PartShopScreen({super.key});

  @override
  State<PartShopScreen> createState() => _PartShopScreenState();
}

class _PartShopScreenState extends State<PartShopScreen> {
  String _selectedCategory = 'All';
  String _selectedSort = '인기순';

  final int _pageSize = 10;
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  List<Product> _products = [];
  StreamSubscription<QuerySnapshot>? _subscription;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _loadProducts() {
    _subscription?.cancel();
    _products.clear();
    _lastDocument = null;
    _hasMore = true;

    _subscription = _buildQuery()
        .limit(_pageSize)
        .snapshots()
        .listen(_onProductsUpdate, onError: _handleError);
  }

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

  void _onProductsUpdate(QuerySnapshot<Map<String, dynamic>> snapshot) {
    if (snapshot.docs.isEmpty) {
      setState(() => _hasMore = false);
      return;
    }
    setState(() {
      _products = snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
      _lastDocument = snapshot.docs.last;
      _hasMore = snapshot.docs.length == _pageSize;
    });
  }

  void _handleError(dynamic error) {
    if (error.toString().contains('requires an index')) {
      _showIndexDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류: $error')),
      );
    }
  }

  void _showIndexDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('인덱스 필요'),
        content: const Text('Firestore 인덱스를 생성해야 합니다. '
            'Firebase 콘솔 > Firestore > 인덱스 탭에서 '
            'brand + lowestAsk (혹은 정렬별 필드) 조합 인덱스를 추가하세요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _lastDocument == null) return;
    try {
      final snapshot = await _buildQuery().startAfterDocument(_lastDocument!).limit(_pageSize).get();
      if (snapshot.docs.isEmpty) {
        setState(() => _hasMore = false);
        return;
      }
      setState(() {
        _products.addAll(snapshot.docs.map((doc) => Product.fromFirestore(doc)));
        _lastDocument = snapshot.docs.last;
        _hasMore = snapshot.docs.length == _pageSize;
      });
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');
    return Scaffold(
      appBar: AppBar(
        title: const Text('부품 스토어'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadProducts),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: ['All', 'CPU', 'GPU', 'RAM', 'SSD', 'Cooler']
                        .map((cat) => DropdownMenuItem(
                      value: cat,
                      child: Text(cat),
                    ))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedCategory = value);
                      _loadProducts();
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
                        .map((sort) => DropdownMenuItem(
                      value: sort,
                      child: Text(sort),
                    ))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedSort = value);
                      _loadProducts();
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _products.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : NotificationListener<ScrollNotification>(
              onNotification: (scrollInfo) {
                if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                  _loadMore();
                }
                return false;
              },
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _products.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _products.length) {
                    // 무한스크롤 로딩
                    return const Center(child: CircularProgressIndicator());
                  }
                  final product = _products[index];
                  return GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(productId: product.id),
                    )),
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
                                errorBuilder: (_, __, ___) =>
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
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  StreamBuilder<DocumentSnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('products')
                                        .doc(product.id)
                                        .snapshots(),
                                    builder: (context, snap) {
                                      final price = snap.data?.get('lastTradedPrice') ?? product.lastTradedPrice;
                                      return Text(
                                        '${formatter.format(price)} 원~',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Theme.of(context).primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
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