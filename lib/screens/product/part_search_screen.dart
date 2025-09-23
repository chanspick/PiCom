import 'dart:async';

import 'package:flutter/material.dart';
import 'package:algolia/algolia.dart';
import 'package:picom/models/part_model.dart'; // Import the Part model
import 'part_detail_screen.dart'; // Import the PartDetailScreen

class PartSearchScreen extends StatefulWidget {
  const PartSearchScreen({super.key});

  @override
  State<PartSearchScreen> createState() => _PartSearchScreenState();
}

class _PartSearchScreenState extends State<PartSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<AlgoliaObjectSnapshot> _results = [];
  bool _isLoading = false;
  Timer? _debounce;

  // Algolia keys are maintained from the original SearchScreen
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

        // Query the 'parts' index
        AlgoliaQuery query = _algolia.instance.index('parts').query(keyword);
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
      appBar: AppBar(title: const Text('부품 검색')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '부품 모델명 검색',
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
                            // Create a Part object from Algolia hit data
                            final part = Part(
                              id: _results[i].objectID,
                              name: hit['name'] ?? '',
                              brand: hit['brand'] ?? '',
                              category: hit['category'] ?? '',
                              modelCode: hit['modelCode'] ?? '', // Add this line
                              imageUrl: hit['imageUrl'] ?? '',
                              specs: hit['specs'] ?? {},
                              createdAt: DateTime.parse(hit['createdAt'] ?? DateTime.now().toIso8601String()),
                            );

                            return ListTile(
                              leading: part.imageUrl.isNotEmpty
                                  ? Image.network(part.imageUrl, width: 50, height: 50, fit: BoxFit.cover)
                                  : const Icon(Icons.memory, size: 50),
                              title: Text(part.name),
                              subtitle: Text('${part.brand} - ${part.category}'),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PartDetailScreen(partId: part.id),
                                  ),
                                );
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
