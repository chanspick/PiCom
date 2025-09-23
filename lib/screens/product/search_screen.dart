
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:algolia/algolia.dart';
import 'package:picom/services/part_service.dart';

class SearchScreen extends StatefulWidget {
  final String? category;

  const SearchScreen({super.key, this.category});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<String> _mergedResults = [];
  List<String> _partsTxtModels = [];
  bool _isLoading = false;
  Timer? _debounce;

  final Algolia _algolia = const Algolia.init(
    applicationId: 'IRHJG9MGL7',
    apiKey: 'a35df64bdcebb5654524e45b231e0998',
  );

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (widget.category != null) {
      setState(() {
        _isLoading = true;
      });
      final allParts = await PartService().loadParts();
      setState(() {
        _partsTxtModels = allParts[widget.category!] ?? [];
        _mergedResults = List.from(_partsTxtModels);
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String keyword) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (keyword.isNotEmpty) {
        setState(() {
          _isLoading = true;
        });

        // 1. Algolia Search
        AlgoliaQuery query = _algolia.instance.index('products').query(keyword);
        if (widget.category != null) {
          query = query.facetFilter('category:${widget.category}');
        }

        final snap = await query.getObjects();
        final algoliaNames = snap.hits.map((h) => h.data['name'] as String).toList();

        // 2. Filter parts.txt models
        final txtNames = _partsTxtModels
            .where((name) => name.toLowerCase().contains(keyword.toLowerCase()))
            .toList();

        // 3. Merge and Deduplicate
        final merged = <String>{...algoliaNames, ...txtNames}.toList();
        merged.sort();

        setState(() {
          _mergedResults = merged;
          _isLoading = false;
        });
      } else {
        // If search is empty, show the initial list from parts.txt (if category is present)
        setState(() {
          _mergedResults = List.from(_partsTxtModels);
        });
      }
    });
  }

  void _clearSearch() {
    _controller.clear();
    setState(() {
      _mergedResults = List.from(_partsTxtModels);
    });
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
                  : _mergedResults.isEmpty
                      ? Center(
                          child: Text(_controller.text.isEmpty
                              ? '검색어를 입력해 주세요'
                              : '검색 결과가 없습니다'))
                      : ListView.builder(
                          itemCount: _mergedResults.length,
                          itemBuilder: (ctx, i) {
                            final modelName = _mergedResults[i];
                            return ListTile(
                              title: Text(modelName),
                              onTap: () {
                                // Only pop with result if a category was provided
                                // This search is for selection, not navigation
                                if (widget.category != null) {
                                  Navigator.pop(context, modelName);
                                }
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
