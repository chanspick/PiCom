import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/part_model.dart';
import '../models/sell_request_model.dart';

// 완제품 판매 시, 각 부품과 개별 가격을 묶어서 전달하기 위한 헬퍼 클래스
class PartToSell {
  final Part part;
  final int price;

  PartToSell({required this.part, required this.price});
}


class SellRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // uploadImages 메서드는 변경 없음
  Future<List<String>> uploadImages(List<File> images, String userId, String uploadId) async {
    final List<String> imageUrls = [];
    for (int i = 0; i < images.length; i++) {
      final File image = images[i];
      final String fileName = 'sell_requests/$userId/$uploadId/image_$i.jpg';
      final Reference ref = _storage.ref().child(fileName);
      final UploadTask uploadTask = ref.putFile(image);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      imageUrls.add(downloadUrl);
    }
    return imageUrls;
  }

  // createSellRequest (단일 부품) 메서드는 변경 없음
  Future<void> createSellRequest({
    required Part part,
    required AgeInfoType ageInfoType,
    required bool isSecondHand,
    required String usageFrequency,
    required String purpose,
    required int requestedPrice,
    required List<File> images,
    required bool hasWarranty,
    int? ageInfoYear,
    int? ageInfoMonth,
    int? warrantyMonthsLeft,
  }) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated.');
    }

    final String requestId = _firestore.collection('sell_requests').doc().id;
    final List<String> imageUrls = await uploadImages(images, currentUser.uid, requestId);

    final SellRequest newRequest = SellRequest(
      requestId: requestId,
      sellerId: currentUser.uid,
      partId: part.partId,
      category: part.category.name, // Enum to String
      brand: part.brand,
      modelName: part.modelName,
      ageInfoType: ageInfoType,
      ageInfoYear: ageInfoYear,
      ageInfoMonth: ageInfoMonth,
      isSecondHand: isSecondHand,
      hasWarranty: hasWarranty,
      warrantyMonthsLeft: warrantyMonthsLeft,
      usageFrequency: usageFrequency,
      purpose: purpose,
      requestedPrice: requestedPrice,
      imageUrls: imageUrls,
      status: SellRequestStatus.pending,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestore.collection('sell_requests').doc(requestId).set(newRequest.toMap());
  }

  /// [수정 완료] 완제품 정보를 받아 여러 부품 판매 요청을 일괄 생성합니다.
  Future<void> createSellRequestsFromFinishedPc({
    required List<PartToSell> partsToSell,
    required List<File> images,
    required AgeInfoType ageInfoType,
    required bool isSecondHand,
    required String usageFrequency,
    required String purpose,
    required bool hasWarranty,
    int? ageInfoYear,
    int? ageInfoMonth,
    int? warrantyMonthsLeft,
  }) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated.');

    final imageBatchId = DateTime.now().millisecondsSinceEpoch.toString();
    final imageUrls = await uploadImages(images, currentUser.uid, imageBatchId);
    final batch = _firestore.batch();

    for (final partData in partsToSell) {
      final part = partData.part;
      final docRef = _firestore.collection('sell_requests').doc();

      final newRequest = SellRequest(
        requestId: docRef.id,
        sellerId: currentUser.uid,
        partId: part.partId,
        // [디버그] PartCategory Enum을 String으로 변환하여 전달
        category: part.category.name,
        brand: part.brand,
        modelName: part.modelName,
        requestedPrice: partData.price,
        imageUrls: imageUrls,
        ageInfoType: ageInfoType,
        isSecondHand: isSecondHand,
        usageFrequency: usageFrequency,
        purpose: purpose,
        hasWarranty: hasWarranty,
        ageInfoYear: ageInfoYear,
        ageInfoMonth: ageInfoMonth,
        warrantyMonthsLeft: warrantyMonthsLeft,
        status: SellRequestStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      batch.set(docRef, newRequest.toMap());
    }
    await batch.commit();
  }


  /// 특정 사용자의 모든 판매 요청 목록을 실시간으로 가져옵니다. (변경 없음)
  Stream<List<SellRequest>> getMySellRequests(String userId) {
    return _firestore
        .collection('sell_requests')
        .where('sellerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => SellRequest.fromFirestore(doc))
        .toList());
  }
}
