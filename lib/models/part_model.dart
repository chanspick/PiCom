// part_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum PartCategory { gpu, cpu, ssd, mainboard }

class Part {
  final String partId;
  final PartCategory category;
  final String brand;
  final String modelName;

  Part({
    required this.partId,
    required this.category,
    required this.brand,
    required this.modelName,
  });

  Map<String, dynamic> toMap() {
    return {
      'partId': partId,
      'category': category.name,
      'brand': brand,
      'modelName': modelName,
    };
  }

  factory Part.fromMap(Map<String, dynamic> map) {
    return Part(
      partId: map['partId'],
      category: PartCategory.values.firstWhere(
              (e) => e.name == map['category'],
          orElse: () => PartCategory.cpu), // 기본 cpu
      brand: map['brand'],
      modelName: map['modelName'],
    );
  }

  factory Part.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Part.fromMap(data);
  }
}
