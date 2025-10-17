import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../models/base_part_model.dart';
import '../models/sell_request_model.dart';

class SellRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 1️⃣ 단일 부품 판매 요청 (개별 부품 판매용)
  Future<String> createSellRequestFromBasePart({
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
    // ⚠️ App Check 토큰 강제 갱신
    try {
      await FirebaseAppCheck.instance.getToken(true); // forceRefresh = true
      print('✅ App Check token refreshed successfully');
    } catch (e) {
      print('⚠️ App Check token refresh failed: $e');
      // 계속 진행 (debug mode에서는 괜찮음)
    }

    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not logged in');
    }

    const uuid = Uuid();
    final requestId = uuid.v4();

    // 이미지 업로드
    final imageUrls = await _uploadImages(userId, requestId, images);

    // SellRequest 생성
    final newRequest = SellRequest(
      requestId: requestId,
      sellerId: userId,
      partId: basePart.basePartId,
      category: basePart.category,
      modelName: basePart.modelName,
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

    // Firestore에 저장
    await _firestore
        .collection('sell_requests')
        .doc(requestId)
        .set(newRequest.toMap());

    print('✅ Sell request created successfully: $requestId');
    return requestId; // ⚠️ requestId 반환 추가
  }

  /// 2️⃣ 완제품 판매 요청 (여러 부품을 개별 가격으로)
  Future<void> createMultipleSellRequests({
    required List<BasePart> baseParts,
    required List<int> prices, // 각 부품의 개별 가격
    required List<XFile> images,
    required AgeInfoType ageInfoType,
    int? ageInfoYear,
    int? ageInfoMonth,
    required bool isSecondHand,
    required bool hasWarranty,
    int? warrantyMonthsLeft,
    required String usageFrequency,
    required String purpose,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('사용자 인증이 필요합니다.');
    }

    if (baseParts.length != prices.length) {
      throw Exception('부품 개수와 가격 개수가 일치하지 않습니다.');
    }

    const uuid = Uuid();
    final uploadGroupId = uuid.v4(); // 모든 요청이 동일한 이미지 공유

    // 이미지 한 번만 업로드
    final imageUrls = await _uploadImages(user.uid, uploadGroupId, images);
    if (imageUrls.isEmpty) {
      throw Exception('이미지 업로드에 실패했습니다.');
    }

    // Firestore Batch 작업
    final batch = _firestore.batch();
    final now = DateTime.now();

    for (int i = 0; i < baseParts.length; i++) {
      final basePart = baseParts[i];
      final price = prices[i];
      final requestId = uuid.v4();
      final docRef = _firestore.collection('sell_requests').doc(requestId);

      final newRequest = SellRequest(
        requestId: requestId,
        sellerId: user.uid,
        partId: basePart.basePartId,
        category: basePart.category,
        modelName: basePart.modelName,
        ageInfoType: ageInfoType,
        ageInfoYear: ageInfoYear,
        ageInfoMonth: ageInfoMonth,
        isSecondHand: isSecondHand,
        requestedPrice: price, // 개별 가격 사용
        imageUrls: imageUrls, // 모든 요청이 동일 이미지 공유
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

    // 일괄 커밋
    await batch.commit();
    print('✅ Multiple sell requests created successfully: ${baseParts.length} parts');
  }

  /// 사용자의 판매 요청 목록 실시간 조회
  Stream<List<SellRequest>> getMySellRequests() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
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

  /// [PRIVATE] 이미지 업로드 (타임아웃 및 에러 핸들링 추가)
  Future<List<String>> _uploadImages(
      String userId,
      String uploadId,
      List<XFile> images,
      ) async {
    final List<String> downloadUrls = [];

    for (int i = 0; i < images.length; i++) {
      try {
        final image = images[i];
        final fileName = 'image_$i.jpg';
        final ref = _storage.ref().child('sell_requests/$userId/$uploadId/$fileName');

        UploadTask uploadTask;
        if (kIsWeb) {
          uploadTask = ref.putData(await image.readAsBytes());
        } else {
          uploadTask = ref.putFile(File(image.path));
        }

        // 업로드 진행 상황 로깅
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = (snapshot.bytesTransferred / snapshot.totalBytes * 100).toStringAsFixed(2);
          print('📤 Uploading image $i: $progress%');
        });

        // ⚠️ 타임아웃 설정 추가 (60초)
        final snapshot = await uploadTask.timeout(
          const Duration(seconds: 60),
          onTimeout: () {
            uploadTask.cancel();
            throw TimeoutException('Upload timeout after 60 seconds');
          },
        );

        final downloadUrl = await snapshot.ref.getDownloadURL();
        downloadUrls.add(downloadUrl);
        print('✅ Successfully uploaded image $i: $downloadUrl');
      } on TimeoutException catch (e) {
        print('⏱️ Timeout uploading image $i: $e');
        throw Exception('이미지 업로드 시간 초과. App Check 설정을 확인하세요.');
      } on FirebaseException catch (e) {
        print('❌ Firebase error uploading image $i: ${e.code} - ${e.message}');
        throw Exception('이미지 업로드 실패: ${e.message}');
      } catch (e) {
        print('❌ Error uploading image $i: $e');
        throw Exception('이미지 업로드 중 오류 발생: $e');
      }
    }

    return downloadUrls;
  }
}
