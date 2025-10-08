
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import '../../models/part_model.dart';
import '../../services/part_service.dart'; // Use PartService
import 'package:picom/services/cart_service.dart';
import 'sell_request_screen.dart';
import '../payment_screen.dart';
import 'part_comment_screen.dart';

class PartDetailScreen extends StatelessWidget {
  final String partId;

  const PartDetailScreen({super.key, required this.partId});

  @override
  Widget build(BuildContext context) {
    final cartService = CartService();
    final partService = PartService(); // Instantiate PartService

    return FutureBuilder<Part?>( // Use PartService to get data
      future: partService.getPartById(partId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('부품 상세 정보')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('부품 상세 정보')),
            body: Center(child: Text('오류: ${snapshot.error}')),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('부품 상세 정보')),
            body: const Center(child: Text('부품을 찾을 수 없습니다.')),
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
                // --- Basic Info ---
                Text(
                  part.modelName,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // --- Dynamic Details based on Part Type ---
                if (part is CpuPart)
                  _CpuDetailsWidget(cpuPart: part)
                // else if (part is GpuPart)
                //   _GpuDetailsWidget(gpuPart: part) // Future extension
                else
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('이 부품 종류에 대한 상세 정보 위젯이 아직 구현되지 않았습니다.'),
                    ),
                  ),


              ],
            ),
          ),
          bottomNavigationBar: BottomAppBar(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        // Purchase logic
                      },
                      child: const Text('구매'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        try {
                          await cartService.addToCart(part.partId, 1);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('장바구니에 담았습니다.')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('오류: $e')),
                            );
                          }
                        }
                      },
                      child: const Text('장바구니'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SellRequestScreen()),
                        );
                      },
                      child: const Text('판매'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => PartCommentScreen(partId: part.partId)),
                        );
                      },
                      child: const Text('댓글'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Widget to display CPU specific details
class _CpuDetailsWidget extends StatelessWidget {
  final CpuPart cpuPart;

  const _CpuDetailsWidget({required this.cpuPart});

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
            const Text(
              'CPU 상세 스펙',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
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


// This remains unchanged for now as it uses dummy data
class _PriceGraphCard extends StatelessWidget {
  const _PriceGraphCard();

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
            const Text(
              '시세 정보',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('2024-07-26', style: TextStyle(color: Colors.grey)),
                Flexible(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(child: _buildPriceInfo('평균가', '1,200,000원', Colors.blue)),
                      const SizedBox(width: 8),
                      Flexible(child: _buildPriceInfo('최저가', '1,100,000원', Colors.red)),
                      const SizedBox(width: 8),
                      Flexible(child: _buildPriceInfo('최고가', '1,300,000원', Colors.green)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    getDrawingHorizontalLine: (value) {
                      return const FlLine(
                        color: Color(0xff37434d),
                        strokeWidth: 0.1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return const FlLine(
                        color: Color(0xff37434d),
                        strokeWidth: 0.1,
                      );
                    },
                  ),
                  titlesData: _getTitlesData(),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: const Color(0xff37434d), width: 1),
                  ),
                  minX: 0,
                  maxX: 29,
                  minY: 950000,
                  maxY: 1350000,
                  lineBarsData: [
                    LineChartBarData(
                      spots: _generateDummyData(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
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

  FlTitlesData _getTitlesData() {
    return FlTitlesData(
      show: true,
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          interval: 7,
          getTitlesWidget: (value, meta) {
            final date = DateTime.now().subtract(Duration(days: 29 - value.toInt()));
            return Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text('${date.month}/${date.day}', style: const TextStyle(fontSize: 10)),
            );
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 60,
          interval: 50000,
          getTitlesWidget: (value, meta) {
            return Text('${(value / 10000).round()}만', style: const TextStyle(fontSize: 10));
          },
        ),
      ),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  Widget _buildPriceInfo(String label, String price, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(price, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }

  List<FlSpot> _generateDummyData() {
    final random = Random();
    return List.generate(30, (index) {
      return FlSpot(index.toDouble(), 1100000 + random.nextDouble() * 150000);
    });
  }
}
