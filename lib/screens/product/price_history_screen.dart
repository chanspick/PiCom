// lib/screens/product/price_history_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:picom/models/base_part_model.dart';
import 'package:picom/models/listing_model.dart';
import 'package:picom/services/listing_service.dart';
import 'package:picom/services/part_service.dart';
import 'package:picom/widgets/price_history_chart.dart'; // 그래프 위젯 import
import 'listing_detail_screen.dart';

class PriceHistoryScreen extends StatefulWidget {
  final BasePart basePart;

  const PriceHistoryScreen({super.key, required this.basePart});

  @override
  State<PriceHistoryScreen> createState() => _PriceHistoryScreenState();
}

class _PriceHistoryScreenState extends State<PriceHistoryScreen> {
  final PartService _partService = PartService();
  final ListingService _listingService = ListingService();
  late Future<List<PricePoint>> _priceHistoryFuture;
  late Stream<List<Listing>> _listingsStream;

  @override
  void initState() {
    super.initState();
    // PartService에 새로 추가한 함수를 호출합니다.
    _priceHistoryFuture = _partService.getPriceHistoryForBasePart(widget.basePart.basePartId);
    // ListingService에 새로 추가한 함수를 호출합니다.
    _listingsStream = _listingService.getListingsForBasePart(widget.basePart.basePartId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.basePart.modelName} 시세'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 24),
                Text(widget.basePart.modelName, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 24),
                // 가격 변동 그래프
                FutureBuilder<List<PricePoint>>(
                  future: _priceHistoryFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(height: 280, child: Center(child: CircularProgressIndicator()));
                    }
                    if (snapshot.hasError || !snapshot.hasData || snapshot.data!.length < 2) {
                      return const SizedBox(height: 280, child: Center(child: Text('가격 기록이 부족합니다.')));
                    }
                    // PriceHistoryChart 위젯에 데이터를 전달하여 그래프를 그립니다.
                    return PriceHistoryChart(priceHistory: snapshot.data!);
                  },
                ),
                const Divider(height: 32),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(children: [ Text('판매중인 매물', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)) ]),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          // 판매중인 실제 매물 목록
          StreamBuilder<List<Listing>>(
            stream: _listingsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SliverToBoxAdapter(child: Center(child: Text('판매중인 매물이 없습니다.')));
              }
              final listings = snapshot.data!;
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    return _ListingTile(listing: listings[index]);
                  },
                  childCount: listings.length,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// 판매중인 매물을 표시하는 타일 위젯
class _ListingTile extends StatelessWidget {
  final Listing listing;
  const _ListingTile({required this.listing});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        title: Text(listing.modelName, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text('컨디션: ${listing.conditionScore}점'),
        trailing: Text('${NumberFormat('#,###').format(listing.price)}원', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        onTap: () {
          // [수정] ListingDetailScreen으로 listingId를 전달하고, 문법 오류를 수정합니다.
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ListingDetailScreen(listingId: listing.listingId),
            ),
          );
        },
      ),
    );
  }
}
