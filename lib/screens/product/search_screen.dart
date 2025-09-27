import 'dart:async';
import 'package:flutter/material.dart';
import 'package:algolia/algolia.dart';
import '../../models/part_model.dart'; // Import the Part model

class SearchScreen extends StatefulWidget {
  final String? category;

  const SearchScreen({super.key, this.category});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<AlgoliaObjectSnapshot> _results = []; // Changed to hold full objects
  bool _isLoading = false;
  Timer? _debounce;

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

        AlgoliaQuery query = _algolia.instance.index('parts').query(keyword);
        if (widget.category != null) {
          query = query.facetFilter('category:${widget.category}');
        }

        final snap = await query.getObjects();
        setState(() {
          _results = snap.hits; // Store the full hits
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

  // Helper to convert string to PartCategory enum
  PartCategory _getPartCategoryFromString(String categoryString) {
    return PartCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == categoryString.toLowerCase(),
      orElse: () => PartCategory.cpu, // Default fallback
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category != null
            ? '${widget.category} 모델 검색'
            : '통합 부품 검색'),
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
                            final hit = _results[i];
                            final data = hit.data;
                            final modelName = data['modelName'] as String? ?? 'N/A';
                            final brand = data['brand'] as String? ?? 'N/A';

                            return ListTile(
                              title: Text(modelName),
                              subtitle: Text(brand),
                              onTap: () {
                                // Create a Part object from the Algolia hit data
                                final part = Part(
                                  partId: hit.objectID,
                                  category: _getPartCategoryFromString(data['category'] as String? ?? ''),
                                  brand: brand,
                                  modelName: modelName,
                                );
                                // Pop with the Part object
                                Navigator.pop(context, part);
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
