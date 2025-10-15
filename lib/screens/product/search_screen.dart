import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// === 수정: Part 대신 BasePart 모델을 import 합니다. ===
import '../../models/base_part_model.dart';
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

  // === 수정: 상태 변수의 타입을 List<Part>에서 List<BasePart>로 변경합니다. ===
  List<BasePart> _results = [];
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

        // SearchService는 이제 List<BasePart>를 반환합니다.
        final results = await _searchService.searchProducts(keyword);

        if (mounted) {
          setState(() {
            _results = results;
            _isLoading = false;
          });
        }
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
            : '대표 모델 검색'),
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
                  // === 수정: Part 대신 BasePart 객체를 사용합니다. ===
                  final basePart = _results[i];
                  return ListTile(
                    title: Text(basePart.modelName),
                    // === 수정: brand 대신 BasePart의 통계 정보를 표시합니다. ===
                    subtitle: Text('매물 ${basePart.listingCount}개 | 최저가 ${NumberFormat('#,###').format(basePart.lowestPrice)}원~'),
                    onTap: () {
                      // === 수정: Part 대신 BasePart 객체를 반환합니다. ===
                      Navigator.pop(context, basePart);
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