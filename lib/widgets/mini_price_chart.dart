import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'price_history_chart.dart'; // For PricePoint

class MiniPriceChart extends StatelessWidget {
  final List<PricePoint> priceHistory;

  const MiniPriceChart({super.key, required this.priceHistory});

  @override
  Widget build(BuildContext context) {
    final spots = priceHistory.map((point) {
      return FlSpot(point.date.millisecondsSinceEpoch.toDouble(), point.price);
    }).toList();

    final minX = spots.first.x;
    final maxX = spots.last.x;
    double minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    double maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final yPadding = (maxY - minY) * 0.1;

    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
        minY: minY - yPadding,
        maxY: maxY + yPadding,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.deepPurple.withOpacity(0.7),
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [Colors.deepPurple.withOpacity(0.3), Colors.deepPurple.withOpacity(0.0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        titlesData: const FlTitlesData(show: false),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
      ),
    );
  }
}
