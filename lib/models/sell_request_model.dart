import 'package:cloud_firestore/cloud_firestore.dart';

enum SellRequestStatus { pending, approved, rejected }

class SellRequest {
  final String requestId;
  final String sellerId;
  final String partCategory; // e.g., CPU, GPU
  final String partModelName; // e.g., Core i9-13900K
  final DateTime purchaseDate;
  final bool hasWarranty;
  final int? warrantyMonthsLeft;
  final String usageFrequency; // e.g., '주 5일, 하루 8시간'
  final String purpose; // e.g., '게임용', '기타 (개발용)'
  final int requestedPrice; // New: Seller's requested price
  final List<String> imageUrls; // New: URLs of uploaded images
  final SellRequestStatus status; // New: Status of the request
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? adminNotes; // New: For admin to add notes
  final int? calculatedConditionScore; // New: Calculated by Python model
  final int? suggestedPrice; // New: Suggested by Python model
  final int? finalPrice; // New: Admin's final decision on price
  final int? finalConditionScore; // New: Admin's final decision on condition score
  final int? sellerCounterOfferPrice; // New: Seller's counter-offer price after seeing suggested price

  SellRequest({
    required this.requestId,
    required this.sellerId,
    required this.partCategory,
    required this.partModelName,
    required this.purchaseDate,
    required this.hasWarranty,
    this.warrantyMonthsLeft,
    required this.usageFrequency,
    required this.purpose,
    required this.requestedPrice,
    required this.imageUrls,
    this.status = SellRequestStatus.pending, // Default to pending
    required this.createdAt,
    this.updatedAt,
    this.adminNotes,
    this.calculatedConditionScore,
    this.suggestedPrice,
    this.finalPrice,
    this.finalConditionScore,
    this.sellerCounterOfferPrice,
  });

  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'sellerId': sellerId,
      'partCategory': partCategory,
      'partModelName': partModelName,
      'purchaseDate': Timestamp.fromDate(purchaseDate),
      'hasWarranty': hasWarranty,
      'warrantyMonthsLeft': warrantyMonthsLeft,
      'usageFrequency': usageFrequency,
      'purpose': purpose,
      'requestedPrice': requestedPrice,
      'imageUrls': imageUrls,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'adminNotes': adminNotes,
      'calculatedConditionScore': calculatedConditionScore,
      'suggestedPrice': suggestedPrice,
      'finalPrice': finalPrice,
      'finalConditionScore': finalConditionScore,
      'sellerCounterOfferPrice': sellerCounterOfferPrice,
    };
  }

  factory SellRequest.fromMap(Map<String, dynamic> map) {
    return SellRequest(
      requestId: map['requestId'],
      sellerId: map['sellerId'],
      partCategory: map['partCategory'],
      partModelName: map['partModelName'],
      purchaseDate: (map['purchaseDate'] as Timestamp).toDate(),
      hasWarranty: map['hasWarranty'],
      warrantyMonthsLeft: map['warrantyMonthsLeft'],
      usageFrequency: map['usageFrequency'],
      purpose: map['purpose'],
      requestedPrice: map['requestedPrice'],
      imageUrls: List<String>.from(map['imageUrls']),
      status: SellRequestStatus.values.firstWhere(
              (e) => e.name == map['status'],
          orElse: () => SellRequestStatus.pending),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
      adminNotes: map['adminNotes'],
      calculatedConditionScore: map['calculatedConditionScore'],
      suggestedPrice: map['suggestedPrice'],
      finalPrice: map['finalPrice'],
      finalConditionScore: map['finalConditionScore'],
      sellerCounterOfferPrice: map['sellerCounterOfferPrice'],
    );
  }

  factory SellRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SellRequest.fromMap(data);
  }
}