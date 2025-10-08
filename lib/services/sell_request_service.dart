import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/part_model.dart';
import '../models/sell_request_model.dart';

class SellRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 이미지 업로드: 원래 시그니처 유지
  Future<List<String>> uploadImages(List<File> images, String userId, String requestId) async {
    final List<String> imageUrls = [];
    for (int i = 0; i < images.length; i++) {
      final File image = images[i];
      final String fileName = 'sell_requests/$userId/$requestId/image_$i.jpg';
      final Reference ref = _storage.ref().child(fileName);
      // 메타데이터는 선택 사항(원래 코드 호환 유지)
      final UploadTask uploadTask = ref.putFile(image);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      imageUrls.add(downloadUrl);
    }
    return imageUrls;
  }

  // 요청 생성: 원래 시그니처/경로 형태 유지, 내부만 보완
  Future<void> createSellRequest({
    required Part part,
    required DateTime purchaseDate,
    required bool hasWarranty,
    int? warrantyMonthsLeft,
    required String usageFrequency,
    required String purpose,
    required int requestedPrice,
    required List<File> images,
  }) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated.');
    }

    // 규칙은 /sell_requests를 사용 → 컬렉션 아이디 생성만 여기서 받고,
    // 실제 기록은 동일 경로로 통일
    final String requestId = _firestore.collection('sell_requests').doc().id;
    final String sellerId = currentUser.uid;

    // 1) 이미지 업로드
    final List<String> imageUrls = await uploadImages(images, sellerId, requestId);

    // 2) 모델 인스턴스 생성(원래 모델 사용)
    final SellRequest newRequest = SellRequest(
      requestId: requestId,
      sellerId: sellerId,
      partId: part.partId,
      category: part.category.name,
      brand: part.brand,
      modelName: part.modelName,
      purchaseDate: purchaseDate,
      hasWarranty: hasWarranty,
      warrantyMonthsLeft: warrantyMonthsLeft,
      usageFrequency: usageFrequency,
      purpose: purpose,
      requestedPrice: requestedPrice,
      imageUrls: imageUrls,
      status: SellRequestStatus.pending,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      adminNotes: null,
    );

    // 3) Firestore 저장: 규칙과 일치하도록 컬렉션 경로를 sell_requests로 고정
    await _firestore.collection('sell_requests').doc(requestId).set(newRequest.toMap());
  }

  // 내 판매요청 조회: 원래 경로 표기를 sell_requests로만 통일
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
