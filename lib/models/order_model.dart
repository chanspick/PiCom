
import 'package:cloud_firestore/cloud_firestore.dart';

enum DeliveryStatus {
  preparing, // 배송 준비중
  shipping,  // 배송중
  delivered, // 배송 완료
}

class Order {
  final String orderId;
  final String productName;
  final DateTime orderDate;
  final DeliveryStatus status;
  final String imageUrl;
  final int price;

  Order({
    required this.orderId,
    required this.productName,
    required this.orderDate,
    required this.status,
    required this.imageUrl,
    required this.price,
  });

  factory Order.fromListing(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    // The backend does not yet support delivery status, so we default to 'preparing'.
    // This can be updated later when the backend is updated.
    DeliveryStatus status = DeliveryStatus.preparing;

    // You could potentially add logic here to derive the status, for example:
    // if (data['deliveryStartedAt'] != null) {
    //   status = DeliveryStatus.shipping;
    // }
    // if (data['deliveredAt'] != null) {
    //   status = DeliveryStatus.delivered;
    // }

    return Order(
      orderId: doc.id,
      productName: data['modelName'] ?? 'Unknown Product',
      orderDate: (data['soldAt'] as Timestamp).toDate(),
      status: status,
      imageUrl: data['imageUrls'] != null && data['imageUrls'].isNotEmpty
          ? data['imageUrls'][0]
          : '',
      price: data['price'] ?? 0,
    );
  }
}
