// lib/services/order_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/listing_model.dart';
import '../models/order_model.dart';
import '../widgets/price_history_chart.dart';


class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // [수정] FirebaseAuth.author -> FirebaseAuth.instance 오타 수정
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
  /// @param partId 조회할 부품의 고유 ID
  Future<List<PricePoint>> getPriceHistoryForPart(String partId) async {
    final snapshot = await _firestore
        .collection('listings')
        .where('partId', isEqualTo: partId)
        .where('status', isEqualTo: ListingStatus.sold.name) // 판매 완료된 것만 조회
        .orderBy('soldAt', descending: false) // 시간순으로 정렬
        .get();

    if (snapshot.docs.isEmpty) {
      return [];
    }

    final pricePoints = snapshot.docs.map((doc) {
      final data = doc.data();
      // soldAt과 price 필드가 모두 있는지 확인
      if (data.containsKey('soldAt') && data['soldAt'] != null && data.containsKey('price')) {
        return PricePoint(
          date: (data['soldAt'] as Timestamp).toDate(),
          price: (data['price'] as num).toDouble(),
        );
      }
      return null;
    }).where((pp) => pp != null).cast<PricePoint>().toList(); // null이 아닌 것만 리스트로 변환

    return pricePoints;
  }


  /// [핵심] 결제 성공 후 호출될 단일 주문 생성 함수입니다.
  /// Firestore Transaction을 사용하여 데이터의 일관성과 원자성을 보장합니다.
  Future<String> createOrder({
    required List<String> listingIds,
    required bool isBundle,
    required Map<String, dynamic> shippingAddress,
  }) async {
    // ... (이하 createOrder 함수는 이전과 동일) ...
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('로그인이 필요합니다.');
    }
    if (listingIds.isEmpty) {
      throw Exception('주문할 상품이 없습니다.');
    }

    final newOrderId = _firestore.collection('orders').doc().id;

    await _firestore.runTransaction((transaction) async {
      final List<DocumentSnapshot<Map<String, dynamic>>> listingDocs = [];
      final List<OrderItem> orderItems = [];

      for (final listingId in listingIds) {
        final docRef = _firestore.collection('listings').doc(listingId);
        final doc = await transaction.get(docRef);
        if (!doc.exists) {
          throw Exception('상품($listingId)을 찾을 수 없습니다.');
        }
        if (doc.data()?['status'] != ListingStatus.available.name) {
          throw Exception('이미 판매된 상품($listingId)이 포함되어 있습니다.');
        }
        listingDocs.add(doc);
      }

      for (final doc in listingDocs) {
        final data = doc.data()!;
        orderItems.add(OrderItem(
          listingId: doc.id,
          partId: data['partId'],
          sellerId: data['sellerId'],
          modelName: data['modelName'],
          brand: data['brand'],
          imageUrl: (data['imageUrls'] as List).isNotEmpty ? data['imageUrls'][0] : '',
          priceAtPurchase: (data['price'] as num).toDouble(),
        ));
      }

      final String orderType;
      final List<AdditionalCharge> additionalCharges = [];
      if (isBundle) {
        orderType = 'bundle';
        additionalCharges.add(AdditionalCharge(description: 'PC 조립 및 안정화 서비스', amount: 50000.0));
      } else {
        orderType = listingIds.length == 1 ? 'singlePart' : 'multipleParts';
      }

      final newOrder = OrderModel(
        orderId: newOrderId,
        buyerId: user.uid,
        items: orderItems,
        additionalCharges: additionalCharges,
        status: OrderStatus.paymentComplete,
        orderType: orderType,
        createdAt: Timestamp.now(),
        shippingAddress: shippingAddress,
      );

      transaction.set(_firestore.collection('orders').doc(newOrderId), newOrder.toMap());

      for (final doc in listingDocs) {
        transaction.update(doc.reference, {
          'status': ListingStatus.sold.name,
          'buyerId': user.uid,
          'soldAt': Timestamp.now(),
        });
      }
    });

    return newOrderId;
  }
}