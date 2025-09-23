
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> purchaseListing(String listingId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in. Cannot make a purchase.');
    }

    final listingRef = _firestore.collection('listings').doc(listingId);

    // Use a transaction to ensure atomicity
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(listingRef);

      if (!snapshot.exists) {
        throw Exception("Listing does not exist!");
      }

      final data = snapshot.data() as Map<String, dynamic>;
      if (data['status'] != 'available') {
        throw Exception("This item is no longer available for purchase.");
      }

      transaction.update(listingRef, {
        'status': 'sold',
        'buyerId': user.uid,
        'soldAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
