
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:cloud_functions/cloud_functions.dart'; // Added import

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance; // Added

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
