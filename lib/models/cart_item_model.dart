
import 'package:cloud_firestore/cloud_firestore.dart';

class CartItem {
  final String productId;
  final String productName;
  final double price;
  int quantity;
  final String imageUrl;
  final Map<String, dynamic> options;
  final Timestamp addedAt;

  CartItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.imageUrl,
    required this.options,
    required this.addedAt,
  });

  factory CartItem.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return CartItem(
      productId: doc.id,
      productName: data['productName'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      quantity: data['quantity'] ?? 0,
      imageUrl: data['imageUrl'] ?? '',
      options: Map<String, dynamic>.from(data['options'] ?? {}),
      addedAt: data['addedAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productName': productName,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'options': options,
      'addedAt': addedAt,
    };
  }
}
