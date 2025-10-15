import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../models/base_part_model.dart';
import '../models/sell_request_model.dart';

class SellRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 단일 BasePart를 기반으로 판매 요청을 생성합니다. (개별 부품 판매용)
  Future<void> createSellRequestFromBasePart({
    required BasePart basePart,
    required AgeInfoType ageInfoType,
    required bool isSecondHand,
    required String usageFrequency,
    required String purpose,
    required int requestedPrice,
    required List<XFile> images,
    required bool hasWarranty,
    int? ageInfoYear,
    int? ageInfoMonth,
    int? warrantyMonthsLeft,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated.');
    }

    const uuid = Uuid();
    final requestId = uuid.v4();
    final imageUrls = await _uploadImages(currentUser.uid, requestId, images);

    final newRequest = SellRequest(
      requestId: requestId,
      sellerId: currentUser.uid,
      partId: basePart.basePartId,
      category: basePart.category,
      modelName: basePart.modelName,
      // brand 필드 제거됨
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

    await _firestore
        .collection('sell_requests')
        .doc(requestId)
        .set(newRequest.toMap());
  }

  /// 여러 BasePart를 기반으로 다수의 판매 요청을 일괄 생성합니다. (완제품 판매용)
  Future<void> createMultipleSellRequestsFromBaseParts({
    required List<BasePart> baseParts,
    required List<XFile> images,
    required AgeInfoType ageInfoType,
    int? ageInfoYear,
    int? ageInfoMonth,
    required bool isSecondHand,
    required int totalPrice,
    required bool hasWarranty,
    int? warrantyMonthsLeft,
    required String usageFrequency,
    required String purpose,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('인증되지 않은 사용자입니다.');
    }

    const uuid = Uuid();
    final uploadGroupId = uuid.v4(); // 모든 이미지들을 그룹화할 고유 ID
    final imageUrls = await _uploadImages(user.uid, uploadGroupId, images);
    if (imageUrls.isEmpty) {
      throw Exception('이미지 업로드에 실패했습니다.');
    }

    final batch = _firestore.batch();
    final now = DateTime.now();
    final pricePerPart =
    (baseParts.isNotEmpty) ? (totalPrice / baseParts.length).round() : 0;

    for (final basePart in baseParts) {
      final requestId = uuid.v4();
      final docRef = _firestore.collection('sell_requests').doc(requestId);

      final newRequest = SellRequest(
        requestId: requestId,
        sellerId: user.uid,
        partId: basePart.basePartId,
        category: basePart.category,
        modelName: basePart.modelName,
        // brand 필드 제거됨
        ageInfoType: ageInfoType,
        ageInfoYear: ageInfoYear,
        ageInfoMonth: ageInfoMonth,
        isSecondHand: isSecondHand,
        requestedPrice: pricePerPart, // 가격 균등 분배
        imageUrls: imageUrls,
        status: SellRequestStatus.pending,
        createdAt: now,
        updatedAt: now,
        hasWarranty: hasWarranty,
        warrantyMonthsLeft: warrantyMonthsLeft,
        usageFrequency: usageFrequency,
        purpose: purpose,
        adminNotes: null,
      );

      batch.set(docRef, newRequest.toMap());
    }

    await batch.commit();
  }

  /// 사용자의 모든 판매 요청 목록을 실시간으로 가져옵니다.
  Stream<List<SellRequest>> getMySellRequests() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]); // 로그인하지 않은 경우 빈 목록 반환
    }
    return _firestore
        .collection('sell_requests')
        .where('sellerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => SellRequest.fromFirestore(doc))
        .toList());
  }

  /// [PRIVATE] 여러 이미지를 Storage에 업로드하고 URL 목록을 반환합니다.
  Future<List<String>> _uploadImages(
      String userId, String uploadId, List<XFile> images) async {
    final List<String> downloadUrls = [];
    for (int i = 0; i < images.length; i++) {
      final image = images[i];
      final fileName = 'image_$i.jpg';
      final ref =
      _storage.ref().child('sell_requests/$userId/$uploadId/$fileName');

      UploadTask uploadTask;
      if (kIsWeb) {
        uploadTask = ref.putData(await image.readAsBytes());
      } else {
        uploadTask = ref.putFile(File(image.path));
      }

      final snapshot = await uploadTask.whenComplete(() => {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      downloadUrls.add(downloadUrl);
    }
    return downloadUrls;
  }
}