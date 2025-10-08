
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../models/order_model.dart' as app_order;
import '../widgets/price_history_chart.dart'; // For PricePoint

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Fetches the orders for the currently logged-in user.
  Future<List<app_order.Order>> getOrdersForCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) {
      // In a real app, you might want to return an empty list 
      // or handle this case in the UI layer.
      return []; 
    }

    final snapshot = await _firestore
        .collection('listings')
        .where('buyerId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'sold')
        .orderBy('soldAt', descending: true)
        .get();

    final orders = snapshot.docs.map((doc) => app_order.Order.fromListing(doc)).toList();
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
      final HttpsCallable callable = _functions.httpsCallable('buyListing');
      await callable.call<Map<String, dynamic>>({
        'listingId': listingId,
      });
      // The Cloud Function handles all the transaction logic, status updates, etc.
    } on FirebaseFunctionsException catch (e) {
      // Re-throw specific HttpsError messages from the Cloud Function
      throw Exception(e.message ?? 'Failed to purchase listing.');
    } catch (e) {
      throw Exception('An unexpected error occurred during purchase: $e');
    }
  }
}
