import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/part_review_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const List<String> _adminEmails = ['wlsrb00g@gmail.com', 'jochanhyeong28@gmail.com'];

  Future<void> createOrUpdateUser({
    required String uid,
    required String email,
    required String name,
    String? photoUrl,
    required String provider,
  }) async {
    final bool isAdmin = _adminEmails.contains(email);

    await _db.collection('users').doc(uid).set(
      {
        'email': email,
        'name': name,
        'photoUrl': photoUrl,
        'provider': provider,
        'lastLogin': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'isAdmin': isAdmin,
      },
      SetOptions(merge: true),
    );
  }

  Future<void> deleteUser(String uid) async {
    await _db.collection('users').doc(uid).delete();
  }

  Future<DocumentSnapshot?> getUser(String uid) async {
    try {
      return await _db.collection('users').doc(uid).get();
    } catch (e) {
      // Consider logging the error
      return null;
    }
  }

  // --- 리뷰 관련 메서드 ---

  // 특정 부품의 리뷰 목록을 실시간으로 가져오기 (정렬 기능 포함)
  Stream<List<PartReview>> getReviewsStream(String partId, {String orderBy = 'createdAt'}) {
    return _db
        .collection('parts')
        .doc(partId)
        .collection('reviews')
        .orderBy(orderBy, descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => PartReview.fromFirestore(doc))
        .toList());
  }

  // 리뷰 추가
  Future<void> addReview(PartReview review) {
    return _db
        .collection('parts')
        .doc(review.partId)
        .collection('reviews')
        .add(review.toFirestore());
  }

  // 리뷰 삭제
  Future<void> deleteReview(String partId, String reviewId) {
    return _db
        .collection('parts')
        .doc(partId)
        .collection('reviews')
        .doc(reviewId)
        .delete();
  }

  // 리뷰 추천/추천 취소
  Future<void> toggleLike(String partId, String reviewId, String userId) {
    DocumentReference reviewRef = _db
        .collection('parts')
        .doc(partId)
        .collection('reviews')
        .doc(reviewId);

    return _db.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(reviewRef);
      if (!snapshot.exists) {
        throw Exception("Review does not exist!");
      }

      PartReview review = PartReview.fromFirestore(snapshot);
      if (review.likes.contains(userId)) {
        // 이미 추천했다면 추천 취소
        transaction.update(reviewRef, {
          'likes': FieldValue.arrayRemove([userId])
        });
      } else {
        // 추천하지 않았다면 추천 추가 (비추천은 제거)
        transaction.update(reviewRef, {
          'likes': FieldValue.arrayUnion([userId]),
          'dislikes': FieldValue.arrayRemove([userId])
        });
      }
    });
  }

  // 리뷰 비추천/비추천 취소
  Future<void> toggleDislike(String partId, String reviewId, String userId) {
    DocumentReference reviewRef = _db
        .collection('parts')
        .doc(partId)
        .collection('reviews')
        .doc(reviewId);

    return _db.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(reviewRef);
      if (!snapshot.exists) {
        throw Exception("Review does not exist!");
      }

      PartReview review = PartReview.fromFirestore(snapshot);
      if (review.dislikes.contains(userId)) {
        // 이미 비추천했다면 비추천 취소
        transaction.update(reviewRef, {
          'dislikes': FieldValue.arrayRemove([userId])
        });
      } else {
        // 비추천하지 않았다면 비추천 추가 (추천은 제거)
        transaction.update(reviewRef, {
          'dislikes': FieldValue.arrayUnion([userId]),
          'likes': FieldValue.arrayRemove([userId])
        });
      }
    });
  }
}