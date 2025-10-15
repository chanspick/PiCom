import 'package:cloud_firestore/cloud_firestore.dart';

// --- Enums (수정 없음) ---

/// 부품의 연식 정보를 어떤 기준으로 받았는지 정의합니다.
enum AgeInfoType {
  originalPurchaseDate,
  manufactureDate,
  unknown,
}

/// 판매 요청의 현재 상태를 정의합니다.
enum SellRequestStatus {
  pending,
  approved,
  rejected,
  sold,
}

// --- Model Class (brand 필드 제거됨) ---

class SellRequest {
  final String requestId;
  final String sellerId;

  // 부품 정보 (BasePart 기반)
  final String partId; // BasePart의 ID (basePartId)가 저장됩니다.
  final String category;
  final String modelName;

  // 핵심 정보: 부품 연식 및 소유 이력
  final AgeInfoType ageInfoType;
  final int? ageInfoYear;
  final int? ageInfoMonth;
  final bool isSecondHand;

  // 기타 정보
  final bool hasWarranty;
  final int? warrantyMonthsLeft;
  final String usageFrequency;
  final String purpose;
  final int requestedPrice;
  final List<String> imageUrls;

  // 관리 정보
  final SellRequestStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? adminNotes;

  SellRequest({
    required this.requestId,
    required this.sellerId,
    required this.partId,
    required this.category,
    // brand 필드 제거됨
    required this.modelName,
    required this.ageInfoType,
    this.ageInfoYear,
    this.ageInfoMonth,
    required this.isSecondHand,
    required this.hasWarranty,
    this.warrantyMonthsLeft,
    required this.usageFrequency,
    required this.purpose,
    required this.requestedPrice,
    required this.imageUrls,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.adminNotes,
  });

  /// Firestore에 저장하기 위한 Map 변환 메서드
  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'sellerId': sellerId,
      'partId': partId,
      'category': category,
      // brand 필드 제거됨
      'modelName': modelName,
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
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'adminNotes': adminNotes,
    };
  }

  /// Firestore 문서를 SellRequest 객체로 변환하는 팩토리 생성자
  factory SellRequest.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return SellRequest(
      requestId: data['requestId'],
      sellerId: data['sellerId'],
      partId: data['partId'],
      category: data['category'],
      // brand 필드 제거됨
      modelName: data['modelName'],
      ageInfoType: AgeInfoType.values.byName(data['ageInfoType'] ?? 'unknown'),
      ageInfoYear: data['ageInfoYear'],
      ageInfoMonth: data['ageInfoMonth'],
      isSecondHand: data['isSecondHand'] ?? false,
      hasWarranty: data['hasWarranty'],
      warrantyMonthsLeft: data['warrantyMonthsLeft'],
      usageFrequency: data['usageFrequency'],
      purpose: data['purpose'],
      requestedPrice: data['requestedPrice'],
      imageUrls: List<String>.from(data['imageUrls']),
      status: SellRequestStatus.values.byName(data['status'] ?? 'pending'),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      adminNotes: data['adminNotes'],
    );
  }
}