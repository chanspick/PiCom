
import 'package:cloud_firestore/cloud_firestore.dart';

class SellRequest {
  final String id;
  final String sellerId;
  final String partCategory;
  final String partName;
  final DateTime purchaseDate;
  final bool hasWarranty;
  final int? warrantyMonthsLeft;
  final String usageFrequency; // e.g., "3 days/week, 4 hours/day"
  final String purpose;
  final String status; // e.g., 'requested', 'shipped', 'inspected', 'listed', 'rejected'
  final DateTime createdAt;

  SellRequest({
    required this.id,
    required this.sellerId,
    required this.partCategory,
    required this.partName,
    required this.purchaseDate,
    required this.hasWarranty,
    this.warrantyMonthsLeft,
    required this.usageFrequency,
    required this.purpose,
    required this.status,
    required this.createdAt,
  });

  factory SellRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SellRequest(
      id: doc.id,
      sellerId: data['sellerId'] ?? '',
      partCategory: data['partCategory'] ?? '',
      partName: data['partName'] ?? '',
      purchaseDate: (data['purchaseDate'] as Timestamp).toDate(),
      hasWarranty: data['hasWarranty'] ?? false,
      warrantyMonthsLeft: data['warrantyMonthsLeft'] as int?,
      usageFrequency: data['usageFrequency'] ?? '',
      purpose: data['purpose'] ?? '',
      status: data['status'] ?? 'requested',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sellerId': sellerId,
      'partCategory': partCategory,
      'partName': partName,
      'purchaseDate': Timestamp.fromDate(purchaseDate),
      'hasWarranty': hasWarranty,
      'warrantyMonthsLeft': warrantyMonthsLeft,
      'usageFrequency': usageFrequency,
      'purpose': purpose,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
