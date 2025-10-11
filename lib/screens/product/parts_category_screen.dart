// lib/screens/product/part_category_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:picom/models/base_part_model.dart'; // [수정] BasePart 모델 import
import 'package:picom/models/part_model.dart';
import 'package:picom/services/part_service.dart';
import 'price_history_screen.dart';
import 'part_search_screen.dart';

class PartsCategoryScreen extends StatefulWidget {
  const PartsCategoryScreen({super.key});
  @override
  State<PartsCategoryScreen> createState() => _PartsCategoryScreenState();
}

class _PartsCategoryScreenState extends State<PartsCategoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<PartCategory> _categories = PartCategory.values;
  final PartService _partService = PartService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('부품 시세'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _categories.map((c) => Tab(text: c.name.toUpperCase())).toList(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PartSearchScreen()));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
                child: const Row(children: [ Icon(Icons.search, color: Colors.grey), SizedBox(width: 8), Text('부품 검색', style: TextStyle(color: Colors.grey),), ],),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _categories.map((category) {
                // [수정] getPartsByCategory -> getBasePartsByCategory 호출
                return StreamBuilder<List<BasePart>>(
                  stream: _partService.getBasePartsByCategory(category),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('오류: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('판매중인 부품이 없습니다.'));
                    }
                    final baseParts = snapshot.data!;
                    return _buildPartGrid(baseParts);
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // [수정] 파라미터 타입을 List<Part> -> List<BasePart>로 변경
  Widget _buildPartGrid(List<BasePart> baseParts) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: baseParts.length,
      itemBuilder: (context, index) {
        final basePart = baseParts[index];
        return _PartCard(basePart: basePart);
      },
    );
  }
}

// [수정] _PartCard가 Part 대신 BasePart를 받도록 변경하고 StatelessWidget으로 변환
class _PartCard extends StatelessWidget {
  final BasePart basePart;
  const _PartCard({required this.basePart});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');

    return GestureDetector(
      onTap: () {
        // [수정] 새로운 PriceHistoryScreen으로 이동
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => PriceHistoryScreen(basePart: basePart),
        ));
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 5,
              child: Container(
                padding: const EdgeInsets.all(12),
                color: Colors.grey[100],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      basePart.modelName,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('최저가', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        Text(
                          basePart.lowestPrice > 0 ? '${formatter.format(basePart.lowestPrice)}원~' : '가격 정보 없음',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).primaryColor),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(Icons.storefront_outlined, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text('${basePart.listingCount}개 매물', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}