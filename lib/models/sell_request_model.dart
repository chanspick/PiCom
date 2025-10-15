import 'package:cloud_firestore/cloud_firestore.dart';

// --- Enums ---

/// 부품의 연식 정보를 어떤 기준으로 받았는지 정의합니다.
enum AgeInfoType {
  /// 최초 신품 구매일 기준 (가장 신뢰도 높음)
  originalPurchaseDate,

  /// 제조년월 기준 (차선책)
  manufactureDate,

  /// 정보를 알 수 없음
  unknown,
}

/// 판매 요청의 현재 상태를 정의합니다.
enum SellRequestStatus {
  /// 검토 대기 중
  pending,

  /// 관리자 승인
  approved,

  /// 관리자 반려
  rejected,

  /// 판매 완료
  sold,
}

// --- Model Class ---

class SellRequest {
  final String requestId;
  final String sellerId;

  // 부품 정보
  final String partId;
  final String category;
  final String brand;
  final String modelName;

  // **핵심 정보: 부품 연식 및 소유 이력**
  final AgeInfoType ageInfoType;
  final int? ageInfoYear;
  final int? ageInfoMonth;
  final bool isSecondHand; // true: 판매자가 중고로 구매, false: 판매자가 신품으로 구매

  // 기타 정보
  final bool hasWarranty;
  final int? warrantyMonthsLeft;
  final String usageFrequency; // 예: "매일 8시간 이상", "주 2-3회"
  final String purpose; // 예: "게이밍", "사무용"
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
    required this.brand,
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
      'brand': brand,
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
      brand: data['brand'],
      modelName: data['modelName'],
      ageInfoType: AgeInfoType.values.byName(data['ageInfoType'] ?? 'unknown'),
      ageInfoYear: data['ageInfoYear'],
      ageInfoMonth: data['ageInfoMonth'],
      isSecondHand: data['isSecondHand'] ?? false, // 데이터가 없을 경우 기본값 false
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