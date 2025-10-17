// lib/services/order_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/listing_model.dart';
import '../models/order_model.dart';
import '../widgets/price_history_chart.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 현재 로그인된 사용자의 모든 주문 목록을 가져옵니다.
  Stream<List<OrderModel>> getOrdersForCurrentUser() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('orders')
        .where('buyerId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => OrderModel.fromMap(doc.data())).toList());
  }

  /// [추가] 특정 부품의 판매 완료된 가격 이력을 가져오는 함수
  Future<List<PricePoint>> getPriceHistoryForPart(String partId) async {
    final snapshot = await _firestore
        .collection('orders')
        .where('status', isEqualTo: 'completed')
        .get();

    List<PricePoint> priceHistory = [];
    for (var orderDoc in snapshot.docs) {
      final orderData = orderDoc.data();
      final items = orderData['items'] as List<dynamic>? ?? [];
      for (var itemMap in items) {
        if (itemMap['partId'] == partId) {
          final createdAt =
              (orderData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          final price = (itemMap['priceAtPurchase'] as num?)?.toDouble() ?? 0.0;
          priceHistory.add(PricePoint(date: createdAt, price: price));
        }
      }
    }
    priceHistory.sort((a, b) => a.date.compareTo(b.date));
    return priceHistory;
  }

  /// 주문을 생성하고 해당 Listing들을 'sold' 상태로 업데이트합니다.
  ///
  /// ✅ [수정] isBundle 파라미터 추가
  Future<String> createOrder({
    required List<String> listingIds,
    bool isBundle = false, // ✅ 추가: 조립 주문 여부
    required Map<String, dynamic> shippingAddress,
    Map<String, double> additionalCharges = const {}, // ✅ double 타입 유지
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    // 1. Listing 조회 및 검증
    final listingDocs = await Future.wait(
      listingIds.map((id) => _firestore.collection('listings').doc(id).get()),
    );

    for (var doc in listingDocs) {
      if (!doc.exists) {
        throw Exception('Listing not found: ${doc.id}');
      }
      final data = doc.data()!;
      if (data['status'] != ListingStatus.available.name) {
        throw Exception('Listing ${doc.id} is not available');
      }
    }

    // 2. OrderItem 생성
    List<OrderItem> orderItems = [];
    double subtotal = 0.0;

    for (var doc in listingDocs) {
      final data = doc.data()!;
      // ✅ int price를 double로 변환
      final price = OrderItem.priceToDouble((data['price'] as num?)?.toInt() ?? 0);
      subtotal += price;

      orderItems.add(OrderItem(
        listingId: doc.id,
        partId: data['partId'] ?? '',
        basePartId: data['basePartId'] ?? '', // ✅ 추가: Listing에서 basePartId 가져오기
        sellerId: data['sellerId'] ?? '',
        modelName: data['modelName'] ?? 'Unknown Model',
        brand: data['brand'] ?? 'Unknown Brand',
        imageUrl: (data['imageUrls'] as List<dynamic>?)?.isNotEmpty == true
            ? data['imageUrls'][0]
            : '',
        priceAtPurchase: price,
        conditionScore: (data['conditionScore'] as num?)?.toInt() ?? 0,
        status: OrderItemStatus.awaitingShipment,
      ));
    }

    // 3. 총액 계산
    double additionalTotal = additionalCharges.values.fold(0.0, (sum, val) => sum + val);
    double finalTotal = subtotal + additionalTotal;

    // 4. Order 문서 생성
    final orderRef = _firestore.collection('orders').doc();
    final order = OrderModel(
      orderId: orderRef.id,
      buyerId: user.uid,
      items: orderItems,
      status: OrderStatus.paymentComplete,
      subtotal: subtotal,
      additionalCharges: additionalCharges,
      finalTotal: finalTotal,
      isBundle: isBundle, // ✅ 추가
      shippingAddress: shippingAddress,
      createdAt: Timestamp.now(),
    );

    // 5. Transaction으로 Order 생성 + Listing 상태 변경
    await _firestore.runTransaction((transaction) async {
      // Order 저장
      transaction.set(orderRef, order.toMap());

      // 각 Listing을 'sold' 상태로 업데이트
      for (var doc in listingDocs) {
        transaction.update(doc.reference, {
          'status': ListingStatus.sold.name,
          'buyerId': user.uid,
          'soldAt': FieldValue.serverTimestamp(),
        });
      }
    });

    return orderRef.id;
  }

  /// 특정 주문의 상세 정보를 가져옵니다.
  Future<OrderModel?> getOrderById(String orderId) async {
    final doc = await _firestore.collection('orders').doc(orderId).get();
    if (!doc.exists) return null;
    return OrderModel.fromMap(doc.data()!);
  }
}
