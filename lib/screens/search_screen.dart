import 'dart:async';

import 'package:flutter/material.dart';
import 'package:algolia/algolia.dart';
import 'package:picom/models/product_model.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<AlgoliaObjectSnapshot> _results = [];
  bool _isLoading = false;
  Timer? _debounce;

  // TODO: For production, securely store and access these keys.
  final Algolia _algolia = const Algolia.init(
    applicationId: 'IRHJG9MGL7',
    apiKey: 'a35df64bdcebb5654524e45b231e0998',
  );

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String keyword) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (keyword.isNotEmpty) {
        setState(() {
          _isLoading = true;
        });

        AlgoliaQuery query = _algolia.instance.index('products').query(keyword);
        final snap = await query.getObjects();

        setState(() {
          _results = snap.hits;
          _isLoading = false;
        });
      } else {
        setState(() {
          _results = [];
        });
      }
    });
  }

  void _clearSearch() {
    _controller.clear();
    setState(() {
      _results = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('부품 검색'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '제품 모델명 검색',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              textInputAction: TextInputAction.search,
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _results.isEmpty
                      ? Center(
                          child: Text(_controller.text.isEmpty
                              ? '검색어를 입력해 주세요'
                              : '검색 결과가 없습니다'))
                      : ListView.builder(
                          itemCount: _results.length,
                          itemBuilder: (ctx, i) {
                            final hit = _results[i].data;
                            // Algolia doesn't support PricePoint directly in this setup
                            // So we create a dummy product object for navigation
                            final product = Product(
                              id: _results[i].objectID,
                              name: hit['name'] ?? '',
                              brand: hit['brand'] ?? '',
                              modelCode: hit['modelCode'] ?? '',
                              imageUrl: hit['imageUrl'] ?? '',
                              lastTradedPrice: (hit['lastTradedPrice'] as num?)?.toDouble() ?? 0.0,
                              priceHistory: [], // Price history is not indexed in Algolia
                            );

                            return ListTile(
                              leading: product.imageUrl.isNotEmpty
                                  ? Image.network(product.imageUrl, width: 50, height: 50, fit: BoxFit.cover)
                                  : const Icon(Icons.memory, size: 50),
                              title: Text(product.name),
                              subtitle: Text(product.brand),
                              onTap: () {
                                Navigator.pop(context, product);
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
