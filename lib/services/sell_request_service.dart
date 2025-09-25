import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/sell_request_model.dart';

class SellRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<String>> uploadImages(List<File> images, String userId, String requestId) async {
    List<String> imageUrls = [];
    for (int i = 0; i < images.length; i++) {
      File image = images[i];
      String fileName = 'sell_requests/$userId/$requestId/image_$i.jpg';
      UploadTask uploadTask = _storage.ref().child(fileName).putFile(image);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      imageUrls.add(downloadUrl);
    }
    return imageUrls;
  }

  Future<void> createSellRequest({
    required String partCategory,
    required String partModelName,
    required DateTime purchaseDate,
    required bool hasWarranty,
    int? warrantyMonthsLeft,
    required String usageFrequency,
    required String purpose,
    required int requestedPrice,
    required List<File> images, // Now accepts File objects
  }) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated.');
    }

    String requestId = _firestore.collection('sellRequests').doc().id;
    String sellerId = currentUser.uid;

    // Upload images first
    List<String> imageUrls = await uploadImages(images, sellerId, requestId);

    SellRequest newRequest = SellRequest(
      requestId: requestId,
      sellerId: sellerId,
      partCategory: partCategory,
      partModelName: partModelName,
      purchaseDate: purchaseDate,
      hasWarranty: hasWarranty,
      warrantyMonthsLeft: warrantyMonthsLeft,
      usageFrequency: usageFrequency,
      purpose: purpose,
      requestedPrice: requestedPrice,
      imageUrls: imageUrls,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      status: SellRequestStatus.pending,
    );

    await _firestore.collection('sellRequests').doc(requestId).set(newRequest.toMap());
  }

  // You might add methods here to fetch user's sell requests, update status, etc.
  Stream<List<SellRequest>> getMySellRequests(String userId) {
    return _firestore.collection('sellRequests')
        .where('sellerId', isEqualTo: userId) // Corrected where clause
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => SellRequest.fromFirestore(doc)).toList());
  }
}