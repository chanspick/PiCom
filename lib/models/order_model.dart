// lib/models/order_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// 주문 전체의 진행 상태를 나타내는 Enum
enum OrderStatus {
  paymentComplete,
  awaitingSellerShipment,
  partiallyArrived,
  allItemsArrived,
  inspecting,
  assembling,
  shippedToBuyer,
  delivered,
  completed,
  cancelled,
}

/// 주문에 포함된 개별 상품의 물류 상태를 나타내는 Enum
enum OrderItemStatus {
  awaitingShipment,
  shippedToCenter,
  arrivedAtCenter,
  inspected,
  failedInspection,
}

/// 주문에 포함된 개별 상품 정보
class OrderItem {
  final String listingId;
  final String partId;
  final String basePartId; // ✅ 추가: BasePart 통계 업데이트용
  final String sellerId;
  final String modelName;
  final String brand;
  final String imageUrl;
  final double priceAtPurchase; // 주문 시점 가격 (기존 유지)
  final int conditionScore;
  final OrderItemStatus status;
  final String? trackingNumber;

  OrderItem({
    required this.listingId,
    required this.partId,
    required this.basePartId, // ✅ 추가
    required this.sellerId,
    required this.modelName,
    required this.brand,
    required this.imageUrl,
    required this.priceAtPurchase,
    required this.conditionScore,
    required this.status,
    this.trackingNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'listingId': listingId,
      'partId': partId,
      'basePartId': basePartId, // ✅ 추가
      'sellerId': sellerId,
      'modelName': modelName,
      'brand': brand,
      'imageUrl': imageUrl,
      'priceAtPurchase': priceAtPurchase,
      'conditionScore': conditionScore,
      'status': status.name,
      'trackingNumber': trackingNumber,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      listingId: map['listingId'] ?? '',
      partId: map['partId'] ?? '',
      basePartId: map['basePartId'] ?? '', // ✅ 추가 (기존 데이터 호환: 빈 문자열)
      sellerId: map['sellerId'] ?? '',
      modelName: map['modelName'] ?? '',
      brand: map['brand'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      priceAtPurchase: (map['priceAtPurchase'] as num?)?.toDouble() ?? 0.0,
      conditionScore: (map['conditionScore'] as num?)?.toInt() ?? 0,
      status: _parseOrderItemStatus(map['status']),
      trackingNumber: map['trackingNumber'],
    );
  }

  // ✅ 추가: 헬퍼 메서드 - int price를 double로 안전하게 변환
  static double priceToDouble(int price) => price.toDouble();

  // ✅ 추가: 헬퍼 메서드 - double을 int로 안전하게 변환
  static int priceToInt(double price) => price.round();
}

OrderItemStatus _parseOrderItemStatus(dynamic statusStr) {
  if (statusStr == null) return OrderItemStatus.awaitingShipment;
  final str = statusStr.toString().toLowerCase();
  for (var status in OrderItemStatus.values) {
    if (status.name.toLowerCase() == str) return status;
  }
  return OrderItemStatus.awaitingShipment;
}

/// 주문 전체 정보
class OrderModel {
  final String orderId;
  final String buyerId;
  final List<OrderItem> items;
  final OrderStatus status;
  final double subtotal;
  final Map<String, double> additionalCharges;
  final double finalTotal; // 기존 필드명 유지
  final bool isBundle; // ✅ 추가: 조립 주문 여부
  final Map<String, dynamic> shippingAddress;
  final Timestamp createdAt; // ✅ 기존 Timestamp 유지
  final Timestamp? completedAt;

  OrderModel({
    required this.orderId,
    required this.buyerId,
    required this.items,
    required this.status,
    required this.subtotal,
    required this.additionalCharges,
    required this.finalTotal,
    this.isBundle = false, // ✅ 추가
    required this.shippingAddress,
    required this.createdAt,
    this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'buyerId': buyerId,
      'items': items.map((item) => item.toMap()).toList(),
      'status': status.name,
      'subtotal': subtotal,
      'additionalCharges': additionalCharges,
      'finalTotal': finalTotal,
      'isBundle': isBundle, // ✅ 추가
      'shippingAddress': shippingAddress,
      'createdAt': createdAt,
      'completedAt': completedAt,
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      orderId: map['orderId'] ?? '',
      buyerId: map['buyerId'] ?? '',
      items: (map['items'] as List<dynamic>?)
          ?.map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
          .toList() ??
          [],
      status: _parseOrderStatus(map['status']),
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      additionalCharges: (map['additionalCharges'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, (value as num).toDouble())) ??
          {},
      finalTotal: (map['finalTotal'] as num?)?.toDouble() ?? 0.0,
      isBundle: map['isBundle'] ?? false, // ✅ 추가 (기존 데이터 호환: false)
      shippingAddress: Map<String, dynamic>.from(map['shippingAddress'] ?? {}),
      createdAt: map['createdAt'] ?? Timestamp.now(),
      completedAt: map['completedAt'],
    );
  }
}

OrderStatus _parseOrderStatus(dynamic statusStr) {
  if (statusStr == null) return OrderStatus.paymentComplete;
  final str = statusStr.toString().toLowerCase();
  for (var status in OrderStatus.values) {
    if (status.name.toLowerCase() == str) return status;
  }
  return OrderStatus.paymentComplete;
}
