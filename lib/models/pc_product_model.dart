import 'package:cloud_firestore/cloud_firestore.dart';

class PCProduct {
  final String id;
  final String name;
  final String category;
  final int price;
  final double performanceScore;
  final String imageUrl;
  final Timestamp createdAt;

  PCProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.performanceScore,
    required this.imageUrl,
    required this.createdAt,
  });

  factory PCProduct.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return PCProduct(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      price: data['price'] ?? 0,
      performanceScore: (data['performanceScore'] ?? 0.0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }
}
