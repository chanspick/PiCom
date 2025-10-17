// lib/models/listing_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum ListingStatus { available, sold }

class Listing {
  final String listingId;
  final String basePartId;      // ✅ 추가: BasePart 참조
  final String partId;           // 호환성 체크용 Part 참조
  final int conditionScore;      // 1~100 컨디션 점수
  final int price;
  final ListingStatus status;
  final String sellerId;
  final String? buyerId;
  final String brand;            // 비정규화: 브랜드명
  final String modelName;        // 비정규화: 모델명
  final DateTime createdAt;
  final DateTime? soldAt;
  final List<String> imageUrls;

  Listing({
    required this.listingId,
    required this.basePartId,    // ✅ 추가
    required this.partId,
    required this.conditionScore,
    required this.price,
    required this.status,
    required this.sellerId,
    this.buyerId,
    required this.brand,
    required this.modelName,
    required this.createdAt,
    this.soldAt,
    required this.imageUrls,
  });

  Map<String, dynamic> toMap() {
    return {
      'listingId': listingId,
      'basePartId': basePartId,   // ✅ 추가
      'partId': partId,
      'conditionScore': conditionScore,
      'price': price,
      'status': status.name,
      'sellerId': sellerId,
      'buyerId': buyerId,
      'brand': brand,
      'modelName': modelName,
      'createdAt': Timestamp.fromDate(createdAt),
      'soldAt': soldAt != null ? Timestamp.fromDate(soldAt!) : null,
      'imageUrls': imageUrls,
    };
  }

  factory Listing.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Listing(
      listingId: doc.id,
      basePartId: data['basePartId'] ?? '',  // ✅ 추가
      partId: data['partId'] ?? '',
      conditionScore: (data['conditionScore'] as num?)?.toInt() ?? 100,
      price: (data['price'] as num?)?.toInt() ?? 0,
      status: data['status'] == 'sold'
          ? ListingStatus.sold
          : ListingStatus.available,
      sellerId: data['sellerId'] ?? '',
      buyerId: data['buyerId'],
      brand: data['brand'] ?? '',
      modelName: data['modelName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      soldAt: (data['soldAt'] as Timestamp?)?.toDate(),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
    );
  }

  factory Listing.fromMap(Map<String, dynamic> data) {
    return Listing(
      listingId: data['listingId'] ?? '',
      basePartId: data['basePartId'] ?? '',  // ✅ 추가
      partId: data['partId'] ?? '',
      conditionScore: (data['conditionScore'] as num?)?.toInt() ?? 100,
      price: (data['price'] as num?)?.toInt() ?? 0,
      status: data['status'] == 'sold'
          ? ListingStatus.sold
          : ListingStatus.available,
      sellerId: data['sellerId'] ?? '',
      buyerId: data['buyerId'],
      brand: data['brand'] ?? '',
      modelName: data['modelName'] ?? '',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      soldAt: data['soldAt'] is Timestamp
          ? (data['soldAt'] as Timestamp).toDate()
          : null,
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
    );
  }

  // copyWith 메서드 (상태 업데이트 시 유용)
  Listing copyWith({
    String? listingId,
    String? basePartId,
    String? partId,
    int? conditionScore,
    int? price,
    ListingStatus? status,
    String? sellerId,
    String? buyerId,
    String? brand,
    String? modelName,
    DateTime? createdAt,
    DateTime? soldAt,
    List<String>? imageUrls,
  }) {
    return Listing(
      listingId: listingId ?? this.listingId,
      basePartId: basePartId ?? this.basePartId,
      partId: partId ?? this.partId,
      conditionScore: conditionScore ?? this.conditionScore,
      price: price ?? this.price,
      status: status ?? this.status,
      sellerId: sellerId ?? this.sellerId,
      buyerId: buyerId ?? this.buyerId,
      brand: brand ?? this.brand,
      modelName: modelName ?? this.modelName,
      createdAt: createdAt ?? this.createdAt,
      soldAt: soldAt ?? this.soldAt,
      imageUrls: imageUrls ?? this.imageUrls,
    );
  }
}
