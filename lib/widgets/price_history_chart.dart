
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 가격 데이터 포인트를 나타내는 데이터 클래스
class PricePoint {
  final DateTime date;
  final double price;

  PricePoint({required this.date, required this.price});
}

/// 전문적인 가격 변동 차트 위젯.
/// 스플라인 보간법, 현재가 반영, 데이터 정렬 등 고급 시각화 기법을 적용합니다.
class PriceHistoryChart extends StatelessWidget {
  final List<PricePoint> priceHistory;
  final double? currentPrice; // Optional: Can be null if not applicable

  const PriceHistoryChart({
    super.key,
    required this.priceHistory,
    this.currentPrice,
  });

  @override
  Widget build(BuildContext context) {
    // 1. 현재가를 포함한 완전한 데이터셋 생성
    final completeData = _buildCompleteDataset();

    // 2. 데이터 유효성 검사 (데이터가 2개 미만일 경우)
    if (completeData.length < 2) {
      return _buildEmptyState();
    }

    // 3. 차트용 데이터로 변환
    final spots = _convertToFlSpots(completeData);
    final chartBounds = _calculateChartBounds(spots);

    // 4. 최종 차트 위젯 반환
    return _buildChart(context, spots, chartBounds);
  }

  /// 현재 거래가를 포함한 완전한 데이터셋을 생성하고 시간순으로 정렬합니다.
  List<PricePoint> _buildCompleteDataset() {
    final sortedHistory = List<PricePoint>.from(priceHistory);

    if (currentPrice != null) {
      final currentTimePoint = PricePoint(
        date: DateTime.now(),
        price: currentPrice!,
      );

      bool shouldAddCurrentPoint = true;
      if (sortedHistory.isNotEmpty) {
        final lastPoint = sortedHistory.last;
        final priceDifference = (lastPoint.price - currentPrice!).abs();
        final timeDifference = DateTime.now().difference(lastPoint.date);

        if (priceDifference < 0.01 && timeDifference.inMinutes < 5) {
          shouldAddCurrentPoint = false;
        }
      }

      if (shouldAddCurrentPoint) {
        sortedHistory.add(currentTimePoint);
      }
    }

    sortedHistory.sort((a, b) => a.date.compareTo(b.date));

    return sortedHistory;
  }

  /// PricePoint 리스트를 FlSpot 리스트로 변환합니다.
  List<FlSpot> _convertToFlSpots(List<PricePoint> data) {
    return data.map((point) {
      return FlSpot(point.date.millisecondsSinceEpoch.toDouble(), point.price);
    }).toList();
  }

  /// 차트 경계값을 동적으로 계산합니다.
  ChartBounds _calculateChartBounds(List<FlSpot> spots) {
    final minX = spots.first.x;
    final maxX = spots.last.x;
    double minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    double maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

    final yPadding = (maxY - minY) * 0.20;
    minY = (minY - yPadding).clamp(0, double.infinity);
    maxY += yPadding;

    final xPadding = (maxX - minX) * 0.05;

    return ChartBounds(
      minX: minX - xPadding,
      maxX: maxX + xPadding,
      minY: minY,
      maxY: maxY,
    );
  }

  /// 메인 차트 위젯을 구성합니다.
  Widget _buildChart(
      BuildContext context,
      List<FlSpot> spots,
      ChartBounds bounds,
      ) {
    final chartColor = Colors.deepPurple;
    final gradientColors = [chartColor.withAlpha(102), chartColor.withAlpha(0)];

    return Container(
      height: 280,
      padding: const EdgeInsets.fromLTRB(16, 24, 24, 16),
      child: LineChart(
        LineChartData(
          minX: bounds.minX,
          maxX: bounds.maxX,
          minY: bounds.minY,
          maxY: bounds.maxY,

          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              preventCurveOverShooting: true,
              color: chartColor,
              barWidth: 3.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  final isLastDot = (index == barData.spots.length - 1) && currentPrice != null;
                  return FlDotCirclePainter(
                    radius: isLastDot ? 6 : 0,
                    color: Colors.white,
                    strokeWidth: 2.5,
                    strokeColor: chartColor,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],

          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 60,
                getTitlesWidget: (value, meta) {
                  if (value == meta.max || value == meta.min) {
                    return const SizedBox();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      NumberFormat.compact().format(value),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
          ),

          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (bounds.maxY - bounds.minY) / 5,
            getDrawingHorizontalLine: (value) {
              return const FlLine(color: Color(0xffe7e8ec), strokeWidth: 1);
            },
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  /// 데이터가 없을 때 표시할 위젯
  Widget _buildEmptyState() {
    return Container(
      height: 280,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            '거래 기록이 부족합니다',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

/// 차트 경계값을 담는 데이터 클래스
class ChartBounds {
  final double minX, maxX, minY, maxY;

  const ChartBounds({
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
  });
}
