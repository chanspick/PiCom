import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import '../../models/part_model.dart';
import '../../services/part_service.dart';
import 'package:picom/services/cart_service.dart';
import 'package:picom/services/order_service.dart'; // 시세 그래프를 위해 추가
import 'package:picom/widgets/price_history_chart.dart'; // 상세 그래프 위젯
import 'package:picom/widgets/part_review_section.dart';
import 'sell_request_screen.dart';
import 'part_comment_screen.dart';

// StatelessWidget에서 StatefulWidget으로 변경하여 시세 정보를 비동기 로드
class PartDetailScreen extends StatefulWidget {
  final String partId;
  const PartDetailScreen({super.key, required this.partId});

  @override
  State<PartDetailScreen> createState() => _PartDetailScreenState();
}

class _PartDetailScreenState extends State<PartDetailScreen> {
  final PartService _partService = PartService();
  final OrderService _orderService = OrderService();
  final CartService _cartService = CartService();

  late Future<Part?> _partFuture;
  late Future<List<PricePoint>> _priceHistoryFuture;

  @override
  void initState() {
    super.initState();
    // initState에서 Future를 한 번만 호출
    _partFuture = _partService.getPartById(widget.partId);
    _priceHistoryFuture = _orderService.getPriceHistoryForPart(widget.partId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Part?>(
      future: _partFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('부품 상세 정보')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('오류')),
            body: Center(child: Text('부품 정보를 불러올 수 없습니다: ${snapshot.error}')),
          );
        }

        final part = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: Text(part.modelName),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- 이미지 자리 (향후 추가) ---
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 24),

                // --- 기본 정보 ---
                Text(
                  part.brand,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  part.modelName,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),

                // --- 시세 정보 그래프 ---
                _PriceGraphCard(priceHistoryFuture: _priceHistoryFuture),
                const SizedBox(height: 24),

                // --- 부품 타입에 따른 동적 상세 정보 ---
                if (part is CpuPart)
                  _CpuDetailsWidget(cpuPart: part)
                else if (part is GpuPart)
                  _GpuDetailsWidget(gpuPart: part)
                else if (part is MainboardPart)
                    _MainboardDetailsWidget(mainboardPart: part)
                  else
                    const Card( // GenericPart 또는 다른 타입들을 위한 fallback
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('이 부품 종류에 대한 상세 스펙 정보가 없습니다.'),
                      ),
                    ),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomAppBar(part),
        );
      },
    );
  }

  void _showReviewSheet(BuildContext context, String partId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 키보드가 올라올 때 시트가 함께 올라가도록 설정
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return PartReviewSection(partId: partId);
      },
    );
  }

  BottomAppBar _buildBottomAppBar(Part part) {
    return BottomAppBar(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.shopping_cart_checkout),
                label: const Text('구매'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12)),
                onPressed: () {
                  /* 구매 로직 */
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('담기'),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12)),
                onPressed: () async {
                  try {
                    await _cartService.addToCart(part.partId, 1);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('장바구니에 담았습니다.')));
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('오류: $e')));
                    }
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.reviews_outlined),
                label: const Text('리뷰'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Theme.of(context).primaryColor),
                ),
                onPressed: () {
                  _showReviewSheet(context, part.partId);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 공용 상세 스펙 행 위젯
Widget _buildSpecRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    ),
  );
}

// --- 각 부품별 상세 정보 위젯들 ---

class _CpuDetailsWidget extends StatelessWidget {
  final CpuPart cpuPart;
  const _CpuDetailsWidget({required this.cpuPart});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('CPU 상세 스펙', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(height: 20, thickness: 1),
            _buildSpecRow('소켓', cpuPart.socket),
            _buildSpecRow('코어', '${cpuPart.cores}코어'),
            _buildSpecRow('스레드', '${cpuPart.threads}스레드'),
            _buildSpecRow('기본 클럭', '${cpuPart.baseClockGhz}GHz'),
            _buildSpecRow('부스트 클럭', '${cpuPart.boostClockGhz}GHz'),
            _buildSpecRow('L3 캐시', '${cpuPart.l3CacheMb}MB'),
            _buildSpecRow('내장그래픽', cpuPart.hasIntegratedGraphics ? '있음 (${cpuPart.igpuName ?? ''})' : '없음'),
            _buildSpecRow('설계전력', '${cpuPart.powerConsumptionW ?? 'N/A'}W'),
            _buildSpecRow('메모리 타입', cpuPart.memory.type),
            _buildSpecRow('메모리 속도', '${cpuPart.memory.maxSpeedMhz}MHz'),
          ],
        ),
      ),
    );
  }
}

class _GpuDetailsWidget extends StatelessWidget {
  final GpuPart gpuPart;
  const _GpuDetailsWidget({required this.gpuPart});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('GPU 상세 스펙', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(height: 20, thickness: 1),
            _buildSpecRow('칩셋', gpuPart.chipset),
            _buildSpecRow('메모리', '${gpuPart.memoryType} ${gpuPart.memorySizeGb}GB'),
            _buildSpecRow('부스트 클럭', '${gpuPart.boostClockMhz ?? 'N/A'}MHz'),
            _buildSpecRow('CUDA 코어', '${gpuPart.cudaCores ?? 'N/A'}'),
            _buildSpecRow('인터페이스', gpuPart.interfaceType ?? 'N/A'),
            _buildSpecRow('권장 파워', '${gpuPart.powerConsumptionW ?? 'N/A'}W'),
          ],
        ),
      ),
    );
  }
}

class _MainboardDetailsWidget extends StatelessWidget {
  final MainboardPart mainboardPart;
  const _MainboardDetailsWidget({required this.mainboardPart});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('메인보드 상세 스펙', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(height: 20, thickness: 1),
            _buildSpecRow('플랫폼', mainboardPart.socket.contains('AM') ? 'AMD' : 'Intel'),
            _buildSpecRow('소켓', mainboardPart.socket),
            _buildSpecRow('칩셋', mainboardPart.chipset),
            _buildSpecRow('폼팩터', mainboardPart.formFactor),
            _buildSpecRow('메모리 타입', mainboardPart.memoryType),
            _buildSpecRow('메모리 슬롯', '${mainboardPart.memorySlots}개'),
            _buildSpecRow('최대 메모리', '${mainboardPart.maxMemoryGb}GB'),
            _buildSpecRow('SATA 포트', '${mainboardPart.sataPorts}개'),
            _buildSpecRow('M.2 슬롯', '${mainboardPart.m2Slots}개'),
          ],
        ),
      ),
    );
  }
}


class _PriceGraphCard extends StatelessWidget {
  final Future<List<PricePoint>> priceHistoryFuture;
  const _PriceGraphCard({required this.priceHistoryFuture});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('시세 정보', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: FutureBuilder<List<PricePoint>>(
                future: priceHistoryFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || !snapshot.hasData || snapshot.data!.length < 2) {
                    return const Center(child: Text('시세 정보가 충분하지 않습니다.'));
                  }
                  // PriceHistoryChart 위젯을 사용하여 실제 데이터로 그래프를 그림
                  return PriceHistoryChart(priceHistory: snapshot.data!);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}