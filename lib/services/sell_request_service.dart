
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/sell_request_model.dart';

class SellRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> createSellRequest({
    required String partCategory,
    required String partName,
    required DateTime purchaseDate,
    required bool hasWarranty,
    int? warrantyMonthsLeft,
    required String usageFrequency,
    required String purpose,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in. Cannot create a sell request.');
    }

    final newRequest = SellRequest(
      id: '', // Firestore will generate this
      sellerId: user.uid,
      partCategory: partCategory,
      partName: partName,
      purchaseDate: purchaseDate,
      hasWarranty: hasWarranty,
      warrantyMonthsLeft: warrantyMonthsLeft,
      usageFrequency: usageFrequency,
      purpose: purpose,
      status: 'requested', // Initial status
      createdAt: DateTime.now(),
    );

    await _firestore.collection('sell_requests').add(newRequest.toFirestore());
  }
}
