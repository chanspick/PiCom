// listing_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum ListingStatus { available, sold }

class Listing {
  final String listingId;
  final String partId;
  final int conditionScore; // 1~100 컨디션 점수
  final int price;
  final ListingStatus status;
  final String sellerId;
  final String? buyerId;
  final String brand; // Added for denormalization
  final String modelName; // Added for denormalization
  final DateTime createdAt;
  final DateTime? soldAt;
  final List<String> imageUrls;

  Listing({
    required this.listingId,
    required this.partId,
    required this.conditionScore,
    required this.price,
    required this.status,
    required this.sellerId,
    this.buyerId,
    required this.brand, // Added
    required this.modelName, // Added
    required this.createdAt,
    this.soldAt,
    required this.imageUrls,
  });

  Map<String, dynamic> toMap() {
    return {
      'listingId': listingId,
      'partId': partId,
      'conditionScore': conditionScore,
      'price': price,
      'status': status.name,
      'sellerId': sellerId,
      'buyerId': buyerId,
      'brand': brand, // Added
      'modelName': modelName, // Added
      'createdAt': Timestamp.fromDate(createdAt),
      'soldAt': soldAt != null ? Timestamp.fromDate(soldAt!) : null,
      'imageUrls': imageUrls,
    };
  }

  factory Listing.fromMap(Map<String, dynamic> map) {
    return Listing(
      listingId: map['listingId'],
      partId: map['partId'],
      conditionScore: map['conditionScore'],
      price: map['price'],
      status: ListingStatus.values.firstWhere(
              (e) => e.name == map['status'],
          orElse: () => ListingStatus.available), // 기본 available
      sellerId: map['sellerId'],
      buyerId: map['buyerId'],
      brand: map['brand'], // Added
      modelName: map['modelName'], // Added
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      soldAt: map['soldAt'] != null ? (map['soldAt'] as Timestamp).toDate() : null,
      imageUrls: List<String>.from(map['imageUrls']),
    );
  }

  factory Listing.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Listing.fromMap(data);
  }
}
