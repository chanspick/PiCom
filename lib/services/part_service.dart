
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/part_model.dart';

class PartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get a stream of all parts
  Stream<List<Part>> getAllParts() {
    return _firestore.collection('parts')
        .orderBy('brand')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Part.fromFirestore(doc)).toList());
  }

  // Get a stream of parts filtered by category
  Stream<List<Part>> getPartsByCategory(PartCategory category) {
    return _firestore.collection('parts')
        .where('category', isEqualTo: category.name)
        .orderBy('brand')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Part.fromFirestore(doc)).toList());
  }

  // Get a single part by ID
  Future<Part?> getPartById(String partId) async {
    final doc = await _firestore.collection('parts').doc(partId).get();
    if (doc.exists) {
      return Part.fromFirestore(doc);
    }
    return null;
  }
}
