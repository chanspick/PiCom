import 'package:cloud_firestore/cloud_firestore.dart';

enum SellRequestStatus { pending, approved, rejected }

class SellRequest {
  final String requestId;
  final String sellerId;
  final String partId; // ID of the part from the 'parts' collection
  final String category; // Denormalized from Part
  final String brand; // Denormalized from Part
  final String modelName; // Denormalized from Part
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

  SellRequest({
    required this.requestId,
    required this.sellerId,
    required this.partId,
    required this.category,
    required this.brand,
    required this.modelName,
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
  });

  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'sellerId': sellerId,
      'partId': partId,
      'category': category,
      'brand': brand,
      'modelName': modelName,
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
    };
  }

  factory SellRequest.fromMap(Map<String, dynamic> map) {
    return SellRequest(
      requestId: map['requestId'],
      sellerId: map['sellerId'],
      partId: map['partId'] ?? '',
      category: map['category'] ?? '',
      brand: map['brand'] ?? '',
      modelName: map['modelName'] ?? '',
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
    );
  }

  factory SellRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SellRequest.fromMap(data);
  }
}