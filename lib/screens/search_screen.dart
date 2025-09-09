import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _keyword = '';
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 임시 검색 결과 (실제론 API 연동)
  List<String> get _results {
    if (_keyword.isEmpty) return [];
    // 예시 데이터
    final allParts = [
      'Intel Core i9-13900K', 'Intel Core i7-13700K', 'AMD Ryzen 9 7950X', 'AMD Ryzen 7 7800X3D',
      'NVIDIA GeForce RTX 4090', 'NVIDIA GeForce RTX 4080', 'AMD Radeon RX 7900 XTX', 'AMD Radeon RX 7800 XT',
      'Samsung 980 Pro 2TB', 'SK Hynix Platinum P41 2TB',
    ];
    return allParts.where((part) => part.toLowerCase().contains(_keyword.toLowerCase())).toList();
  }

  void _clearSearch() {
    setState(() {
      _keyword = '';
      _controller.clear();
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
                suffixIcon: _keyword.isNotEmpty
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
              onChanged: (val) {
                setState(() => _keyword = val);
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _results.isEmpty
                  ? Center(child: Text(_keyword.isEmpty ? '검색어를 입력해 주세요' : '검색 결과가 없습니다'))
                  : ListView.builder(
                itemCount: _results.length,
                itemBuilder: (ctx, i) {
                  final result = _results[i];
                  return ListTile(
                    leading: const Icon(Icons.memory),
                    title: Text(result),
                    onTap: () {
                      // 현재 화면을 닫고 결과값을 반환
                      Navigator.pop(context, result);
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