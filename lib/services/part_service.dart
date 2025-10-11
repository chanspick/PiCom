import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/part_model.dart';
import '../models/part_comment_model.dart';
import '../models/base_part_model.dart';
import '../widgets/price_history_chart.dart'; // PricePoint를 위해 추가
class PartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  Future<List<PricePoint>> getPriceHistoryForBasePart(String basePartId) async {
    final snapshot = await _firestore
        .collection('base_part_prices')
        .doc(basePartId)
        .collection('daily_stats')
        .orderBy('date', descending: false)
        .get();

    if (snapshot.docs.isEmpty) {
      return [];
    }

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return PricePoint(
        date: (data['date'] as Timestamp).toDate(),
        // 그래프는 평균가 기준으로 그리는 것이 일반적입니다.
        price: (data['averagePrice'] as num).toDouble(),
      );
    }).toList();
  }
  // ======================================================
  // [새로 추가된 함수] '부품 시세' 페이지를 위한 함수
  // ======================================================

  Stream<List<BasePart>> getBasePartsByCategory(PartCategory category) {
    return _firestore
        .collection('base_parts')
        .where('category', isEqualTo: category.name)
        .where('listingCount', isGreaterThan: 0) // 판매중인 매물이 있는 모델만 표시
        .orderBy('listingCount', descending: true) // 매물 많은 순으로 정렬
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => BasePart.fromFirestore(doc))
        .toList());
  }
  // Get a stream of parts filtered by category
  Stream<List<Part>> getPartsByCategory(PartCategory category) {
    return _firestore.collection('parts')
        .where('category', isEqualTo: category.name)
        .orderBy('brand')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Part.fromFirestore(doc)).toList());
  }

  /// Get a list of partIds for a given category string.
  Future<List<String>> getPartIdsForCategory(String category) async {
    if (category == 'All') {
      return []; // 'All' should be handled separately, maybe return all part IDs or an empty list.
    }
    final querySnapshot = await _firestore
        .collection('parts')
        .where('category', isEqualTo: category.toLowerCase())
        .get();
    return querySnapshot.docs.map((doc) => doc.id).toList();
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