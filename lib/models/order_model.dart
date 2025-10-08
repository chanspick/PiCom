// lib/models/order_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

// 배송 상태를 나타내는 Enum
enum DeliveryStatus {
  processing,   // 주문 처리 중
  preparing,    // 상품 준비 중
  shipped,      // 배송 시작
  delivered,    // 배송 완료
  cancelled,    // 주문 취소
  returned,     // 반품
}

// 주문에 포함된 개별 상품 정보
class OrderItem {
  final String listingId;       // 구매한 상품 ID
  final String sellerId;        // 판매자 ID
  final String productName;     // 상품명 (기록용)
  final int quantity;           // 수량
  final double priceAtPurchase; // 구매 시점의 가격

  OrderItem({
    required this.listingId,
    required this.sellerId,
    required this.productName,
    required this.quantity,
    required this.priceAtPurchase,
  });

  Map<String, dynamic> toMap() {
    return {
      'listingId': listingId,
      'sellerId': sellerId,
      'productName': productName,
      'quantity': quantity,
      'priceAtPurchase': priceAtPurchase,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      listingId: map['listingId'] ?? '',
      sellerId: map['sellerId'] ?? '',
      productName: map['productName'] ?? '',
      quantity: map['quantity']?.toInt() ?? 0,
      priceAtPurchase: map['priceAtPurchase']?.toDouble() ?? 0.0,
    );
  }
}

// 부가 비용 정보 (예: 조립비, 배송비)
class AdditionalCharge {
  final String description; // 비용 설명 (예: '프리미엄 조립 서비스')
  final double amount;      // 비용 금액

  AdditionalCharge({required this.description, required this.amount});

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'amount': amount,
    };
  }

  factory AdditionalCharge.fromMap(Map<String, dynamic> map) {
    return AdditionalCharge(
      description: map['description'] ?? '',
      amount: map['amount']?.toDouble() ?? 0.0,
    );
  }
}

class OrderModel {
  final String orderId;           // 주문 ID
  final String buyerId;           // 구매자 ID
  final List<OrderItem> items;    // 주문 상품 목록
  final List<AdditionalCharge> additionalCharges; // 부가 비용 목록
  final double itemsTotal;        // 상품 총액
  final double chargesTotal;      // 부가 비용 총액
  final double finalTotal;        // 최종 결제 금액
  final DeliveryStatus status;    // 배송 상태
  final Timestamp orderDate;      // 주문 일시
  // + 배송지 정보, 연락처 등 추가 가능

  OrderModel({
    required this.orderId,
    required this.buyerId,
    required this.items,
    this.additionalCharges = const [],
    required this.status,
    required this.orderDate,
  })  : itemsTotal = items.fold(0.0, (sum, item) => sum + (item.priceAtPurchase * item.quantity)),
        chargesTotal = additionalCharges.fold(0.0, (sum, charge) => sum + charge.amount),
        finalTotal = items.fold(0.0, (sum, item) => sum + (item.priceAtPurchase * item.quantity)) +
                   additionalCharges.fold(0.0, (sum, charge) => sum + charge.amount);


  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'buyerId': buyerId,
      'items': items.map((item) => item.toMap()).toList(),
      'additionalCharges': additionalCharges.map((charge) => charge.toMap()).toList(),
      'itemsTotal': itemsTotal,
      'chargesTotal': chargesTotal,
      'finalTotal': finalTotal,
      'status': status.name, // .name is better than .toString() for enums
      'orderDate': orderDate,
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      orderId: map['orderId'] ?? '',
      buyerId: map['buyerId'] ?? '',
      items: List<OrderItem>.from((map['items'] as List<dynamic>?)?.map((x) => OrderItem.fromMap(x as Map<String, dynamic>)) ?? []),
      additionalCharges: List<AdditionalCharge>.from((map['additionalCharges'] as List<dynamic>?)?.map((x) => AdditionalCharge.fromMap(x as Map<String, dynamic>)) ?? []),
      status: DeliveryStatus.values.firstWhere((e) => e.name == map['status'], orElse: () => DeliveryStatus.processing),
      orderDate: map['orderDate'] ?? Timestamp.now(),
    );
  }
}