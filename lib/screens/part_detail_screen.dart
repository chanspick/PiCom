import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart'; // Add this import
import 'dart:math'; // Add this import
import '../models/part_model.dart';
import '../models/product_model.dart'; // Add this import

class PartDetailScreen extends StatelessWidget {
  final String partId;

  const PartDetailScreen({super.key, required this.partId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('부품 상세 정보'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('parts').doc(partId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('오류: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('부품을 찾을 수 없습니다.'));
          }

          final part = Part.fromFirestore(snapshot.data!); // Use the Part model

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (part.imageUrl.isNotEmpty)
                  Center(
                    child: Image.network(
                      part.imageUrl,
                      height: 200,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image, size: 100, color: Colors.grey),
                    ),
                  )
                else
                  Center(
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
                    ),
                  ),
                const SizedBox(height: 20),
                Text(
                  part.name,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '브랜드: ${part.brand}',
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  '카테고리: ${part.category}',
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                const Text(
                  '주요 사양',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                if (part.specs.isNotEmpty)
                  ...part.specs.entries.map((entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Text(
                          '${entry.key}: ${entry.value}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ))
                else
                  const Text(
                    '등록된 사양 정보가 없습니다.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                const SizedBox(height: 20),

                // --- New Section: Price Statistics and Trend ---
                const Text(
                  '가격 정보',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('products')
                      .where('modelCode', isEqualTo: part.modelCode)
                      .get(),
                  builder: (context, productSnapshot) {
                    if (productSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (productSnapshot.hasError) {
                      return Center(child: Text('제품 가격 정보 오류: ${productSnapshot.error}'));
                    }
                    if (!productSnapshot.hasData || productSnapshot.data!.docs.isEmpty) {
                      return const Text('연결된 제품 가격 정보가 없습니다.', style: TextStyle(fontSize: 16, color: Colors.grey));
                    }

                    final products = productSnapshot.data!.docs
                        .map((doc) => Product.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
                        .toList();

                    double lowestPrice = double.infinity;
                    double totalPrice = 0;
                    int productCount = 0;

                    for (var product in products) {
                      if (product.lastTradedPrice > 0) {
                        if (product.lastTradedPrice < lowestPrice) {
                          lowestPrice = product.lastTradedPrice;
                        }
                        totalPrice += product.lastTradedPrice;
                        productCount++;
                      }
                    }

                    final averagePrice = productCount > 0 ? totalPrice / productCount : 0.0;

                    // Extract price history from the first product
                    final List<PricePoint> priceHistory = products.isNotEmpty ? products.first.priceHistory : [];

                    // Prepare data for fl_chart
                    final List<FlSpot> spots = priceHistory.map((point) {
                      return FlSpot(point.date.millisecondsSinceEpoch.toDouble(), point.price);
                    }).toList();

                    // Sort spots by x-value (date)
                    spots.sort((a, b) => a.x.compareTo(b.x));

                    // Determine min/max x and y for chart
                    double minX = spots.isNotEmpty ? spots.first.x : 0;
                    double maxX = spots.isNotEmpty ? spots.last.x : 1;
                    double minY = spots.isNotEmpty ? spots.map((spot) => spot.y).reduce(min) : 0;
                    double maxY = spots.isNotEmpty ? spots.map((spot) => spot.y).reduce(max) : 1;

                    // Add some padding to min/max Y
                    minY = (minY * 0.9).floorToDouble();
                    maxY = (maxY * 1.1).ceilToDouble();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '최저가: ${lowestPrice == double.infinity ? 'N/A' : '${lowestPrice.toStringAsFixed(0)} 원'}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          '평균가: ${averagePrice == 0.0 ? 'N/A' : '${averagePrice.toStringAsFixed(0)} 원'}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          '가격 추이 (차트)',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 200,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: spots.isEmpty
                              ? const Center(
                                  child: Text(
                                    '가격 추이 데이터가 없습니다.',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                )
                              : LineChart(
                                  LineChartData(
                                    gridData: const FlGridData(show: false),
                                    titlesData: FlTitlesData(
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          interval: (maxX - minX) / 4, // Show 5 labels
                                          getTitlesWidget: (value, meta) {
                                            // Convert timestamp back to date string
                                            final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                                            return SideTitleWidget(
                                              meta: meta,
                                              space: 8.0,
                                              child: Text(
                                                '${date.month}/${date.day}',
                                                style: const TextStyle(fontSize: 10),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          interval: (maxY - minY) / 4, // Show 5 labels
                                          getTitlesWidget: (value, meta) {
                                            return SideTitleWidget(
                                              meta: meta,
                                              space: 8.0,
                                              child: Text(
                                                '${value.toInt()}',
                                                style: const TextStyle(fontSize: 10),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    ),
                                    borderData: FlBorderData(
                                      show: true,
                                      border: Border.all(color: const Color(0xff37434d), width: 1),
                                    ),
                                    minX: minX,
                                    maxX: maxX,
                                    minY: minY,
                                    maxY: maxY,
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: spots,
                                        isCurved: true,
                                        color: Colors.blue,
                                        barWidth: 2,
                                        isStrokeCapRound: true,
                                        dotData: const FlDotData(show: false),
                                        belowBarData: BarAreaData(show: false),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ],
                    );
                  },
                ),
                // --- End New Section ---
              ],
            ),
          );
        },
      ),
    );
  }
}
