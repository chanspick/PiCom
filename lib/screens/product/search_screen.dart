import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/part_model.dart';
import '../../services/search_service.dart';

class SearchScreen extends StatefulWidget {
  final String? category;

  const SearchScreen({super.key, this.category});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final SearchService _searchService = SearchService();
  List<Part> _results = [];
  bool _isLoading = false;
  Timer? _debounce;

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
        // Use SearchService
        final results = await _searchService.searchProducts(keyword);
        setState(() {
          _results = results;
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
                            // Now we have a proper Part object
                            final part = _results[i];
                            return ListTile(
                              title: Text(part.modelName), // Use correct field
                              subtitle: Text(part.brand),   // Use correct field
                              onTap: () {
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