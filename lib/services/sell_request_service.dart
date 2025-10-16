import 'dart:async';
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

  // 타임아웃 설정
  static const Duration _uploadTimeout = Duration(seconds: 30);
  static const Duration _downloadUrlTimeout = Duration(seconds: 10);
  static const Duration _firestoreTimeout = Duration(seconds: 15);

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
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('로그인이 필요합니다');
      }

      // 이미지 검증 - 빠른 실패
      if (images.isEmpty) {
        throw Exception('최소 1개의 이미지가 필요합니다');
      }

      final uuid = Uuid();
      final sellRequestId = uuid.v4();

      // 이미지 업로드 (타임아웃 적용)
      List<String> imageUrls;
      try {
        imageUrls = await _uploadImages(
          currentUser.uid,
          sellRequestId,
          images,
        );
      } catch (e) {
        throw Exception('이미지 업로드 실패: ${e.toString()}');
      }

      // 업로드 결과 검증
      if (imageUrls.isEmpty) {
        throw Exception('이미지 업로드가 완료되지 않았습니다');
      }

      // ✅ Map으로 직접 생성 (FieldValue 사용)
      final sellRequestData = {
        'requestId': sellRequestId,
        'sellerId': currentUser.uid,
        'partId': basePart.basePartId,
        'category': basePart.category,
        'modelName': basePart.modelName,
        'ageInfoType': ageInfoType.name,
        'ageInfoYear': ageInfoYear,
        'ageInfoMonth': ageInfoMonth,
        'isSecondHand': isSecondHand,
        'hasWarranty': hasWarranty,
        'warrantyMonthsLeft': warrantyMonthsLeft,
        'usageFrequency': usageFrequency,
        'purpose': purpose,
        'requestedPrice': requestedPrice,
        'imageUrls': imageUrls,
        'status': SellRequestStatus.pending.name,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'adminNotes': null,
      };

      // Firestore에 저장 (타임아웃 적용)
      try {
        await _firestore
            .collection('sellRequests')
            .doc(sellRequestId)
            .set(sellRequestData)
            .timeout(_firestoreTimeout);
      } catch (e) {
        // Firestore 저장 실패 시 업로드된 이미지 정리 시도
        _cleanupImages(currentUser.uid, sellRequestId);
        throw Exception('판매 요청 저장 실패: ${e.toString()}');
      }

      return sellRequestId;
    } on TimeoutException catch (e) {
      throw Exception('요청 시간이 초과되었습니다. 네트워크 연결을 확인해주세요.');
    } catch (e) {
      rethrow;
    }
  }

  /// 2️⃣ 여러 부품 동시 판매 요청 (컴퓨터 전체 판매용)
  Future<List<String>> createMultipleSellRequests({
    required List<BasePart> baseParts,
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
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('로그인이 필요합니다');
      }

      // 검증 - 빠른 실패
      if (baseParts.isEmpty) {
        throw Exception('최소 1개의 부품이 필요합니다');
      }
      if (images.isEmpty) {
        throw Exception('최소 1개의 이미지가 필요합니다');
      }

      final uuid = Uuid();
      final batchId = uuid.v4();

      // 이미지 업로드 (타임아웃 적용)
      List<String> imageUrls;
      try {
        imageUrls = await _uploadImages(
          currentUser.uid,
          batchId,
          images,
        );
      } catch (e) {
        throw Exception('이미지 업로드 실패: ${e.toString()}');
      }

      if (imageUrls.isEmpty) {
        throw Exception('이미지 업로드가 완료되지 않았습니다');
      }

      // 배치 작업 준비
      final batch = _firestore.batch();
      final List<String> sellRequestIds = [];

      for (var basePart in baseParts) {
        final sellRequestId = uuid.v4();
        sellRequestIds.add(sellRequestId);

        // ✅ Map으로 직접 생성 (FieldValue 사용)
        final sellRequestData = {
          'requestId': sellRequestId,
          'sellerId': currentUser.uid,
          'partId': basePart.basePartId,
          'category': basePart.category,
          'modelName': basePart.modelName,
          'ageInfoType': ageInfoType.name,
          'ageInfoYear': ageInfoYear,
          'ageInfoMonth': ageInfoMonth,
          'isSecondHand': isSecondHand,
          'hasWarranty': hasWarranty,
          'warrantyMonthsLeft': warrantyMonthsLeft,
          'usageFrequency': usageFrequency,
          'purpose': purpose,
          'requestedPrice': requestedPrice,
          'imageUrls': imageUrls,
          'status': SellRequestStatus.pending.name,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'adminNotes': null,
        };

        final docRef = _firestore.collection('sellRequests').doc(sellRequestId);
        batch.set(docRef, sellRequestData);
      }

      // 배치 커밋 (타임아웃 적용)
      try {
        await batch.commit().timeout(_firestoreTimeout);
      } catch (e) {
        // 배치 커밋 실패 시 이미지 정리 시도
        _cleanupImages(currentUser.uid, batchId);
        throw Exception('판매 요청 일괄 저장 실패: ${e.toString()}');
      }

      return sellRequestIds;
    } on TimeoutException catch (e) {
      throw Exception('요청 시간이 초과되었습니다. 네트워크 연결을 확인해주세요.');
    } catch (e) {
      rethrow;
    }
  }

  /// 3️⃣ 이미지 업로드 (타임아웃 및 예외 처리 강화)
  Future<List<String>> _uploadImages(
      String userId,
      String uploadId,
      List<XFile> images,
      ) async {
    final List<String> downloadUrls = [];

    for (int i = 0; i < images.length; i++) {
      final image = images[i];
      final fileName = 'image_$i.jpg';
      final ref = _storage.ref().child('sell_requests/$userId/$uploadId/$fileName');

      try {
        UploadTask uploadTask;

        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          uploadTask = ref.putData(bytes);
        } else {
          uploadTask = ref.putFile(File(image.path));
        }

        // 업로드 완료 대기 (타임아웃 적용)
        final TaskSnapshot taskSnapshot = await uploadTask.timeout(
          _uploadTimeout,
          onTimeout: () {
            uploadTask.cancel();
            throw TimeoutException('이미지 ${i + 1} 업로드 시간 초과');
          },
        );

        // Download URL 가져오기 (타임아웃 적용)
        final String downloadUrl = await taskSnapshot.ref
            .getDownloadURL()
            .timeout(_downloadUrlTimeout);

        downloadUrls.add(downloadUrl);
      } on TimeoutException {
        // 타임아웃 발생 시 이미 업로드된 이미지 정리
        _cleanupImages(userId, uploadId);
        throw Exception('이미지 ${i + 1} 업로드가 시간 초과되었습니다');
      } on FirebaseException catch (e) {
        // Firebase 관련 에러
        _cleanupImages(userId, uploadId);
        throw Exception('이미지 ${i + 1} 업로드 실패: ${e.message}');
      } catch (e) {
        // 기타 에러
        _cleanupImages(userId, uploadId);
        throw Exception('이미지 ${i + 1} 업로드 중 오류 발생: ${e.toString()}');
      }
    }

    return downloadUrls;
  }

  /// 4️⃣ 업로드 실패 시 이미지 정리 (백그라운드)
  void _cleanupImages(String userId, String uploadId) {
    // 비동기로 실행하되 에러는 무시 (정리 실패해도 메인 로직에 영향 없게)
    _storage
        .ref()
        .child('sell_requests/$userId/$uploadId')
        .listAll()
        .then((result) {
      for (var item in result.items) {
        item.delete().catchError((_) {});
      }
    }).catchError((_) {});
  }

  /// 5️⃣ 내 판매 요청 목록 조회
  Stream<List<SellRequest>> getMySellRequests() {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      // 로그인하지 않은 경우 빈 스트림 반환
      return Stream.value([]);
    }

    return _firestore
        .collection('sellRequests')
        .where('sellerId', isEqualTo: currentUser.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          // ✅ fromFirestore 사용 (DocumentSnapshot 전달)
          return SellRequest.fromFirestore(doc);
        } catch (e) {
          print('판매 요청 파싱 오류 (ID: ${doc.id}): $e');
          return null;
        }
      }).whereType<SellRequest>().toList(); // null 제거
    }).handleError((error) {
      // 스트림 에러 처리
      print('판매 요청 목록 조회 오류: $error');
      return <SellRequest>[];
    });
  }
}
