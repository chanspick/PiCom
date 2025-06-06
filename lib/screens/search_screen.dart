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
    return List.generate(5, (i) => '$_keyword 결과 ${i + 1}');
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
        title: const Text('검색'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: '검색어를 입력하세요',
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
                // 실제 API 연동 시 debounce 처리 권장
              },
              onSubmitted: (val) {
                setState(() => _keyword = val);
                // TODO: 실제 API 호출 로직
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _results.isEmpty
                  ? const Center(child: Text('검색어를 입력해 주세요'))
                  : ListView.builder(
                itemCount: _results.length,
                itemBuilder: (ctx, i) => ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(_results[i]),
                  onTap: () {
                    // 키보드 내리기
                    FocusScope.of(context).unfocus();
                    // TODO: 결과 선택 시 원하는 동작
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}