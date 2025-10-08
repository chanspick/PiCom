
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cart_item_model.dart';
import '../models/listing_model.dart';
import '../services/listing_service.dart';

import '../models/order_model.dart';
import '../widgets/price_history_chart.dart'; // For PricePoint

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;


  /// Fetches the orders for the currently logged-in user from the 'orders' collection.
  Future<List<OrderModel>> getOrdersForCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) {
      return [];
    }

    final snapshot = await _firestore
        .collection('orders')
        .where('buyerId', isEqualTo: user.uid)
        .orderBy('orderDate', descending: true)
        .get();

    final orders = snapshot.docs.map((doc) => OrderModel.fromMap(doc.data())).toList();
    return orders;
  }


  /// Fetches the price history for a single partId.
  Future<List<PricePoint>> getPriceHistoryForPart(String partId) async {
    // We use a collection group query on 'lineItems' for efficiency.
    // This assumes a subcollection named 'lineItems' exists within each order document.
    final snapshot = await _firestore
        .collectionGroup('lineItems')
        .where('partId', isEqualTo: partId)
        .get();

    final pricePoints = <PricePoint>[];
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>?;
      // Assuming the lineItem doc contains 'soldAt' and 'price' fields.
      if (data != null && data.containsKey('soldAt') && data.containsKey('price')) {
        pricePoints.add(PricePoint(
          date: (data['soldAt'] as Timestamp).toDate(),
          price: (data['price'] as num).toDouble(),
        ));
      }
    }

    pricePoints.sort((a, b) => a.date.compareTo(b.date));
    return pricePoints;
  }

  Future<void> purchaseListing(String listingId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in. Cannot make a purchase.');
    }

    try {
      // 즉시 구매는 아이템이 하나인 장바구니와 동일합니다.
      // CartItem 모델의 실제 생성자에 맞게, productId를 listingId로 사용합니다.
      // 다른 필드들은 createOrders에서 listing을 다시 조회하므로 임시값을 사용해도 괜찮습니다.
      final singleItem = CartItem(
        productId: listingId,
        quantity: 1,
        productName: '', // 임시값
        price: 0,      // 임시값
        imageUrl: '',  // 임시값
        options: {},   // 임시값
        addedAt: Timestamp.now(),
      );

      // 표준 주문 생성 메소드를 호출합니다.
      await createOrders(
        buyerId: user.uid,
        cartItems: [singleItem],
      );
    } catch (e) {
      throw Exception('An unexpected error occurred during purchase: $e');
    }
  }

  /// Creates one or more orders from a list of cart items and optional additional charges.
  /// Groups items by seller and creates a separate order for each seller.
  /// Returns a list of created order IDs.
  Future<List<String>> createOrders({
    required String buyerId,
    required List<CartItem> cartItems,
    List<AdditionalCharge> additionalCharges = const [],
  }) async {
    if (cartItems.isEmpty) {
      throw Exception("Cannot create an order with no items.");
    }

    final listingService = ListingService();
    final createdOrderIds = <String>[];

    // 1. Group cart items by sellerId
    final Map<String, List<CartItem>> itemsBySeller = {};
    for (final cartItem in cartItems) {
      // CartItem.productId가 Listing의 ID 역할을 합니다.
      final listing = await listingService.getListing(cartItem.productId).first;
      (itemsBySeller[listing.sellerId] ??= []).add(cartItem);
    }

    // 2. Create an order for each seller
    for (final sellerEntry in itemsBySeller.entries) {
      final sellerId = sellerEntry.key;
      final sellerCartItems = sellerEntry.value;

      // 3. Convert CartItems to OrderItems
      final List<OrderItem> orderItems = [];
      for (final cartItem in sellerCartItems) {
        final listing = await listingService.getListing(cartItem.productId).first;
        
        orderItems.add(OrderItem(
          listingId: listing.listingId,          // Correct field
          sellerId: listing.sellerId,
          productName: listing.modelName,        // Correct field
          quantity: cartItem.quantity,
          priceAtPurchase: listing.price.toDouble(), // Correct type
        ));
      }

      // 4. Create the OrderModel
      final newOrderId = _firestore.collection('orders').doc().id;
      final newOrder = OrderModel(
        orderId: newOrderId,
        buyerId: buyerId,
        items: orderItems,
        additionalCharges: additionalCharges,
        status: DeliveryStatus.processing,
        orderDate: Timestamp.now(),
      );

      // 5. Save the order to Firestore
      await _firestore.collection('orders').doc(newOrderId).set(newOrder.toMap());
      createdOrderIds.add(newOrderId);

      // 6. Update listing status for each item in the order
      for (final item in orderItems) {
        final listingRef = _firestore.collection('listings').doc(item.listingId);
        await listingRef.update({
          'status': ListingStatus.sold.name, // Enum to string
          'buyerId': buyerId,
          'soldAt': Timestamp.now(),
        });
      }
    }

    return createdOrderIds;
  }
}
