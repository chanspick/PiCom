import 'package:cloud_firestore/cloud_firestore.dart';

/// 가격 변동 그래프의 한 점을 나타내는 데이터 클래스
class PricePoint {
  final DateTime date;
  final double price;

  PricePoint({required this.date, required this.price});
}

/// 상품의 정의와 시세 정보를 모두 포함하는 Product 모델
class Product {
  final String id;
  final String name;
  final String brand;
  final String modelCode;
  final String imageUrl;
  final double lastTradedPrice;
  final List<PricePoint> priceHistory;

  Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.modelCode,
    required this.imageUrl,
    required this.lastTradedPrice,
    required this.priceHistory,
  });

  // Firestore 데이터를 Product 객체로 변환하는 factory 생성자
  factory Product.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};

    // Firestore의 priceHistory (Map의 배열)를 List<PricePoint>으로 변환
    final historyData = data['priceHistory'] as List<dynamic>? ?? [];
    final priceHistory = historyData.map((pointData) {
      final pointMap = pointData as Map<String, dynamic>;
      return PricePoint(
        date: (pointMap['date'] as Timestamp).toDate(),
        price: (pointMap['price'] as num).toDouble(),
      );
    }).toList();

    return Product(
      id: snapshot.id,
      name: data['name'] ?? '',
      brand: data['brand'] ?? '',
      modelCode: data['modelCode'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      lastTradedPrice: (data['lastTradedPrice'] as num?)?.toDouble() ?? 0.0,
      priceHistory: priceHistory,
    );
  }
}
