
import 'package:cloud_firestore/cloud_firestore.dart';

class Listing {
  final String id;
  final String partId; // Link to the 'parts' collection
  final String sellerId; // The original seller who sent the item to us

  // Denormalized fields for efficient display and filtering
  final String partName;
  final String brand;
  final String partCategory;

  final double price;
  final String condition; // e.g., 'Like New', 'Good', 'Fair'
  final String description; // Notes from our inspection
  final List<String> imageUrls; // Photos taken by us

  final String status; // e.g., 'available', 'sold'
  final DateTime createdAt; // When we listed the item

  // These fields are filled when the item is sold
  final String? buyerId;
  final DateTime? soldAt;

  Listing({
    required this.id,
    required this.partId,
    required this.sellerId,
    required this.partName,
    required this.brand,
    required this.partCategory,
    required this.price,
    required this.condition,
    required this.description,
    required this.imageUrls,
    required this.status,
    required this.createdAt,
    this.buyerId,
    this.soldAt,
  });

  factory Listing.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Listing(
      id: doc.id,
      partId: data['partId'] ?? '',
      sellerId: data['sellerId'] ?? '',
      partName: data['partName'] ?? 'No Name',
      brand: data['brand'] ?? 'No Brand',
      partCategory: data['partCategory'] ?? 'Etc', // Added
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      condition: data['condition'] ?? '',
      description: data['description'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      status: data['status'] ?? 'available',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      buyerId: data['buyerId'] as String?,
      soldAt: (data['soldAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'partId': partId,
      'sellerId': sellerId,
      'partName': partName,
      'brand': brand,
      'partCategory': partCategory, // Added
      'price': price,
      'condition': condition,
      'description': description,
      'imageUrls': imageUrls,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'buyerId': buyerId,
      'soldAt': soldAt != null ? Timestamp.fromDate(soldAt!) : null,
    };
  }
}
