
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:algolia/algolia.dart';

class SearchScreen extends StatefulWidget {
  final String? category;

  const SearchScreen({super.key, this.category});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<String> _mergedResults = []; // Will only hold Algolia results now
  bool _isLoading = false;
  Timer? _debounce;

  final Algolia _algolia = const Algolia.init(
    applicationId: 'IRHJG9MGL7',
    apiKey: 'a35df64bdcebb5654524e45b231e0998',
  );

  @override
  void initState() {
    super.initState();
    // No initial data loading from local file needed anymore
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // _loadInitialData() method removed

  void _onSearchChanged(String keyword) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (keyword.isNotEmpty) {
        setState(() {
          _isLoading = true;
        });

        // Algolia Search
        AlgoliaQuery query = _algolia.instance.index('parts').query(keyword); // Changed index to 'parts'
        if (widget.category != null) {
          query = query.facetFilter('category:${widget.category}');
        }

        final snap = await query.getObjects();
        // Assuming Algolia returns 'modelName' directly from Part model
        final algoliaModelNames = snap.hits.map((h) => h.data['modelName'] as String).toList(); // Changed from 'name' to 'modelName'

        // No local parts.txt models to filter or merge
        final merged = algoliaModelNames; // Only Algolia results now
        merged.sort();

        setState(() {
          _mergedResults = merged;
          _isLoading = false;
        });
      } else {
        // If search is empty, clear results
        setState(() {
          _mergedResults = [];
        });
      }
    });
  }

  void _clearSearch() {
    _controller.clear();
    setState(() {
      _mergedResults = []; // Clear results on clear search
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
