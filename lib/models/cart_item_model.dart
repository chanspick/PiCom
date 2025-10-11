// lib/models/cart_item_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CartItem {
  final String productId;     // Firestore 문서 ID (listingId와 동일)
  final String productName;   // 'modelName' 필드에서 읽어온 값
  final double price;
  final int quantity;         // 항상 1
  final String imageUrl;
  final Timestamp addedAt;

  CartItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.imageUrl,
    required this.addedAt,
  });

  factory CartItem.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CartItem(
      productId: doc.id,
      // [수정] 'productName' -> 'modelName'으로 Firestore 필드명 변경
      productName: data['modelName'] ?? '이름 없음',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      // [수정] Firestore의 quantity 필드를 읽도록 변경 (항상 1)
      quantity: (data['quantity'] as num?)?.toInt() ?? 1,
      imageUrl: data['imageUrl'] ?? '',
      addedAt: data['addedAt'] ?? Timestamp.now(),
    );
  }
}