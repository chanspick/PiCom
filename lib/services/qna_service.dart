import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:picom/models/qna_post_model.dart';
import 'package:picom/models/community_comment_model.dart';

class QnaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'posts';

  Stream<List<QnaPost>> getPosts({QnaCategory? category, String sortBy = 'createdAt'}) {
    Query query = _firestore.collection(_collection);

    if (category != null) {
      query = query.where('category', isEqualTo: category.name);
    }

    query = query.orderBy(sortBy, descending: true);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => QnaPost.fromMap(doc.data() as Map<String, dynamic>)).toList();
    });
  }

  Future<void> addPost(QnaPost post) async {
    final docRef = _firestore.collection(_collection).doc();
    await docRef.set(post.copyWith(id: docRef.id, createdAt: Timestamp.now()).toMap());
  }

  Future<QnaPost> getPost(String postId) async {
    final doc = await _firestore.collection(_collection).doc(postId).get();
    return QnaPost.fromMap(doc.data() as Map<String, dynamic>);
  }

  Stream<QnaPost> getPostStream(String postId) {
    return _firestore.collection(_collection).doc(postId).snapshots().map((doc) {
      return QnaPost.fromMap(doc.data() as Map<String, dynamic>);
    });
  }

  Future<String> getUserName(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return (doc.data() as Map<String, dynamic>)['displayName'] ?? 'Unknown User';
    } catch (e) {
      return 'Unknown User';
    }
  }

  Stream<List<CommunityComment>> getComments(String postId) {
    return _firestore
        .collection(_collection)
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => CommunityComment.fromFirestore(doc)).toList();
    });
  }

Future<void> addComment({
  required String postId,
  required String authorId, 
  required String authorName,
  required String content,
}) async {
  await _firestore.collection(_collection).doc(postId).collection('comments').add({
    'userId': authorId, 
    'authorName': authorName,
    'content': content,
    'createdAt': Timestamp.now(),
    'likedBy': [],
  });
}

  Future<void> togglePostLike(String postId, String userId) async {
    final docRef = _firestore.collection(_collection).doc(postId);
    final doc = await docRef.get();
    if (doc.exists) {
      final post = QnaPost.fromMap(doc.data()!);
      final likedBy = List<String>.from(post.likedBy);
      if (likedBy.contains(userId)) {
        likedBy.remove(userId);
      } else {
        likedBy.add(userId);
      }
      await docRef.update({'likedBy': likedBy, 'likes': likedBy.length});
    }
  }

  Future<void> updatePostStatus(String postId, QnaStatus status) async {
    await _firestore.collection(_collection).doc(postId).update({'status': status.name});
  }
}
