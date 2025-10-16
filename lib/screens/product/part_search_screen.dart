import 'package:flutter/material.dart';
import '../../models/base_part_model.dart';
import '../../services/search_service.dart';
import 'part_detail_screen.dart'; // 부품 상세 화면

import 'package:flutter/material.dart';
// === BasePart로 변경 ===
import '../../models/base_part_model.dart';
import '../../services/search_service.dart';
import 'part_detail_screen.dart'; // 부품 상세 화면

class PartSearchScreen extends StatefulWidget {
  const PartSearchScreen({super.key});

  @override
  State<PartSearchScreen> createState() => _PartSearchScreenState();
}

class _PartSearchScreenState extends State<PartSearchScreen> {
  final SearchService _searchService = SearchService();
  // === List<BasePart>로 변경 ===
  List<BasePart> _searchResults = [];
  bool _isLoading = false;
  String _searchTerm = '';

  void _onSearchChanged(String term) {
    setState(() {
      _searchTerm = term;
    });
    if (term.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });
      _searchService.searchProducts(term).then((results) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          onChanged: _onSearchChanged,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '부품 모델명 검색...',
            border: InputBorder.none,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _searchTerm.isEmpty
          ? const Center(child: Text('검색어를 입력해주세요.'))
          : _searchResults.isEmpty
          ? const Center(child: Text('검색 결과가 없습니다.'))
          : ListView.builder(
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final part = _searchResults[index];
          return ListTile(
            // === BasePart에는 imageUrl이 없으므로 기본 아이콘 표시 ===
            leading: const Icon(Icons.memory, size: 50),
            title: Text(part.modelName),
            subtitle: Text('${part.category} • 최저가: ${part.lowestPrice}원'),
            onTap: () {
              // === BasePart 객체를 반환 ===
              Navigator.pop(context, part);
            },
          );
        },
      ),
    );
  }
}
