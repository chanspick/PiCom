import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/part_model.dart';
import '../models/part_comment_model.dart';

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

  Stream<List<PartComment>> getPartComments(String partId, {String sortBy = 'createdAt'}) {
    return _firestore
        .collection('parts')
        .doc(partId)
        .collection('comments')
        .orderBy(sortBy, descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => PartComment.fromFirestore(doc)).toList();
    });
  }

  Future<void> addPartComment({
    required String partId,
    required String authorId,
    required String authorName,
    required String content,
    String? parentId,
  }) async {
    await _firestore.collection('parts').doc(partId).collection('comments').add({
      'authorId': authorId,
      'authorName': authorName,
      'content': content,
      'createdAt': Timestamp.now(),
      'likedBy': [],
      'likes': 0,
      'parentId': parentId,
    });
  }

  Future<void> togglePartCommentLike({
    required String partId,
    required String commentId,
    required String userId,
  }) async {
    final docRef = _firestore.collection('parts').doc(partId).collection('comments').doc(commentId);
    final doc = await docRef.get();
    if (doc.exists) {
      final comment = PartComment.fromFirestore(doc);
      final likedBy = List<String>.from(comment.likedBy);
      if (likedBy.contains(userId)) {
        likedBy.remove(userId);
      } else {
        likedBy.add(userId);
      }
      await docRef.update({'likedBy': likedBy, 'likes': likedBy.length});
    }
  }

  Future<void> deletePartComment({
    required String partId,
    required String commentId,
  }) async {
    await _firestore.collection('parts').doc(partId).collection('comments').doc(commentId).delete();
  }
}
