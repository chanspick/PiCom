// lib/models/order_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// 주문 전체의 진행 상태를 나타내는 Enum
/// 우리의 중앙 관리형 비즈니스 흐름에 맞춰 재정의되었습니다.
enum OrderStatus {
  paymentComplete,        // 결제 완료 (주문의 시작)
  awaitingSellerShipment, // 판매자 발송 대기 (모든 판매자가 우리에게 보내길 기다림)
  partiallyArrived,       // 일부 상품 도착 (일부 판매자만 보낸 상태)
  allItemsArrived,        // 모든 상품 도착 (검수/조립 시작 가능)
  inspecting,             // 검수 중
  assembling,             // 조립 중 (조립 주문의 경우)
  shippedToBuyer,         // 구매자에게 발송 완료
  delivered,              // 배송 완료
  completed,              // 정산 등 모든 절차 완료
  cancelled,              // 주문 취소
}

/// 주문에 포함된 개별 상품의 물류 상태를 나타내는 Enum
enum OrderItemStatus {
  awaitingShipment, // 판매자가 우리에게 보내기 전
  shippedToCenter,  // 판매자가 우리에게 발송함
  arrivedAtCenter,  // 우리가 수령함
  inspected,        // 검수 완료
  failedInspection, // 검수 실패
}

/// 주문에 포함된 개별 상품 정보
class OrderItem {
  final String listingId;
  final String partId; // 호환성 체크 및 데이터 분석을 위한 원본 부품 ID
  final String sellerId;
  final String modelName; // 주문 시점의 모델명 (기록용)
  final String brand;     // 주문 시점의 브랜드 (기록용)
  final String imageUrl;  // 주문 시점의 대표 이미지 URL
  final double priceAtPurchase;
  final OrderItemStatus status; // 개별 아이템의 상태

  OrderItem({
    required this.listingId,
    required this.partId,
    required this.sellerId,
    required this.modelName,
    required this.brand,
    required this.imageUrl,
    required this.priceAtPurchase,
    this.status = OrderItemStatus.awaitingShipment, // 생성 시 기본값
  });

  Map<String, dynamic> toMap() {
    return {
      'listingId': listingId,
      'partId': partId,
      'sellerId': sellerId,
      'modelName': modelName,
      'brand': brand,
      'imageUrl': imageUrl,
      'priceAtPurchase': priceAtPurchase,
      'status': status.name,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      listingId: map['listingId'] ?? '',
      partId: map['partId'] ?? '',
      sellerId: map['sellerId'] ?? '',
      modelName: map['modelName'] ?? '',
      brand: map['brand'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      priceAtPurchase: (map['priceAtPurchase'] as num?)?.toDouble() ?? 0.0,
      status: OrderItemStatus.values.firstWhere(
            (e) => e.name == map['status'],
        orElse: () => OrderItemStatus.awaitingShipment,
      ),
    );
  }
}

/// 부가 비용 정보 (예: 조립비)
class AdditionalCharge {
  final String description;
  final double amount;

  AdditionalCharge({required this.description, required this.amount});

  Map<String, dynamic> toMap() {
    return {'description': description, 'amount': amount};
  }

  factory AdditionalCharge.fromMap(Map<String, dynamic> map) {
    return AdditionalCharge(
      description: map['description'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// 구매자의 단일 결제 건을 나타내는 주문 모델
class OrderModel {
  final String orderId;
  final String buyerId;
  final List<OrderItem> items;
  final List<AdditionalCharge> additionalCharges;
  final double itemsTotal;
  final double chargesTotal;
  final double finalTotal;
  final OrderStatus status;
  final String orderType; // 'singlePart', 'multipleParts', 'bundle'
  final Timestamp createdAt;
  final Map<String, dynamic> shippingAddress; // 배송지 정보

  OrderModel({
    required this.orderId,
    required this.buyerId,
    required this.items,
    this.additionalCharges = const [],
    required this.status,
    required this.orderType,
    required this.createdAt,
    required this.shippingAddress,
  })  : itemsTotal = items.fold(0.0, (sum, item) => sum + item.priceAtPurchase),
        chargesTotal = additionalCharges.fold(0.0, (sum, charge) => sum + charge.amount),
        finalTotal = items.fold(0.0, (sum, item) => sum + item.priceAtPurchase) +
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
      'status': status.name,
      'orderType': orderType,
      'createdAt': createdAt,
      'shippingAddress': shippingAddress,
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      orderId: map['orderId'] ?? '',
      buyerId: map['buyerId'] ?? '',
      items: List<OrderItem>.from((map['items'] as List<dynamic>?)
          ?.map((x) => OrderItem.fromMap(x as Map<String, dynamic>)) ?? []),
      additionalCharges: List<AdditionalCharge>.from(
          (map['additionalCharges'] as List<dynamic>?)
              ?.map((x) => AdditionalCharge.fromMap(x as Map<String, dynamic>)) ?? []),
      status: OrderStatus.values.firstWhere(
            (e) => e.name == map['status'],
        orElse: () => OrderStatus.paymentComplete,
      ),
      orderType: map['orderType'] ?? 'multipleParts',
      createdAt: map['createdAt'] ?? Timestamp.now(),
      shippingAddress: Map<String, dynamic>.from(map['shippingAddress'] ?? {}),
    );
  }
}