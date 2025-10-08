import 'package:flutter/material.dart';
import '../../models/part_model.dart';
import '../../services/search_service.dart';
import 'part_detail_screen.dart'; // 부품 상세 화면

class PartSearchScreen extends StatefulWidget {
  const PartSearchScreen({super.key});

  @override
  State<PartSearchScreen> createState() => _PartSearchScreenState();
}

class _PartSearchScreenState extends State<PartSearchScreen> {
  final SearchService _searchService = SearchService();
  List<Part> _searchResults = [];
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
                          leading: part.imageUrl != null
                              ? Image.network(part.imageUrl!, width: 50, height: 50, fit: BoxFit.cover)
                              : const Icon(Icons.image, size: 50),
                          title: Text(part.modelName), // name -> modelName
                          subtitle: Text(part.brand),   // brand
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PartDetailScreen(partId: part.partId),
                              ),
                            );
                          },
                        );
                      },
                    ),
    );
  }
}