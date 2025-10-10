import 'package:flutter/material.dart';
import 'package:picom/models/part_model.dart';
import 'package:picom/services/order_service.dart';
import 'package:picom/widgets/mini_price_chart.dart';
import 'package:picom/widgets/price_history_chart.dart';
import '../../services/part_service.dart';
import 'part_detail_screen.dart';
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
        title: const Text('부품 시세'), // 제목 변경
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _categories.map((category) => Tab(text: category.name.toUpperCase())).toList(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PartSearchScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey),
                    SizedBox(width: 8),
                    Text(
                      '부품 검색 (Algolia)',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _categories.map((category) {
                return StreamBuilder<List<Part>>(
                  stream: _partService.getPartsByCategory(category),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('오류: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('부품 데이터를 불러올 수 없습니다.'));
                    }

                    final parts = snapshot.data!;
                    return _buildPartGrid(parts);
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartGrid(List<Part> parts) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: parts.length,
      itemBuilder: (context, index) {
        final part = parts[index];
        return _PartCard(part: part);
      },
    );
  }
}

class _PartCard extends StatefulWidget {
  final Part part;
  const _PartCard({required this.part});

  @override
  State<_PartCard> createState() => _PartCardState();
}

class _PartCardState extends State<_PartCard> {
  late Future<List<PricePoint>> _priceHistoryFuture;
  final OrderService _orderService = OrderService();

  @override
  void initState() {
    super.initState();
    _priceHistoryFuture = _orderService.getPriceHistoryForPart(widget.part.partId);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => PartDetailScreen(partId: widget.part.partId),
        ));
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 6,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ==================== 수정된 부분 ====================
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                // Stack과 이미지 플레이스홀더를 제거하고 FutureBuilder를 바로 배치합니다.
                child: FutureBuilder<List<PricePoint>>(
                  future: _priceHistoryFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)));
                    }
                    // 오류 또는 데이터가 없을 때도 회색 배경을 표시하여 레이아웃을 유지합니다.
                    if (snapshot.hasError) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Center(child: Icon(Icons.error_outline, color: Colors.red, size: 30)),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.length < 2) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Text(
                            '가격 내역 없음',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      );
                    }
                    // 데이터가 있으면 MiniPriceChart를 보여줍니다.
                    return MiniPriceChart(priceHistory: snapshot.data!);
                  },
                ),
              ),
            ),
            // =====================================================
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                // Column의 정렬을 수정하여 안정적인 레이아웃 확보
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround, // 공간을 균등하게 배분
                  crossAxisAlignment: CrossAxisAlignment.center, // 수평 중앙 정렬
                  children: [
                    // 모델명이 길 경우를 대비해 Flexible 위젯 사용
                    Flexible(
                      child: Text(
                        // 모델명이 비어있을 경우 fallback 텍스트 표시
                        (widget.part.modelName.isNotEmpty) ? widget.part.modelName : "이름 정보 없음",
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      widget.part.brand,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
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