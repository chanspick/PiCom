import 'package:cloud_firestore/cloud_firestore.dart';

class Part {
  final String id;
  final String category;
  final String brand;
  final String name;
  final String modelCode; // Added for linking with Product
  final String imageUrl; // Placeholder for image URL
  final DateTime createdAt;

  Part({
    required this.id,
    required this.category,
    required this.brand,
    required this.name,
    required this.modelCode, // Added
    this.imageUrl = '', // Default empty string
    required this.createdAt,
  });

  // Factory constructor for creating a Part from a Firestore document
  factory Part.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Part(
      id: doc.id,
      category: data['category'] ?? '',
      brand: data['brand'] ?? '',
      name: data['name'] ?? '',
      modelCode: data['modelCode'] ?? '', // Added
      imageUrl: data['imageUrl'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Method to convert a Part object to a Firestore-compatible map
  Map<String, dynamic> toFirestore() {
    return {
      'category': category,
      'brand': brand,
      'name': name,
      'modelCode': modelCode, // Added
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
