import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:picom/models/community_post_model.dart';
import 'package:picom/models/community_comment_model.dart';

class CommunityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Post Methods
  Stream<List<CommunityPost>> getPosts({String sortBy = 'createdAt', String? searchQuery}) {
    Query<Map<String, dynamic>> query = _firestore.collection('posts');

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.where('title', isGreaterThanOrEqualTo: searchQuery).where('title', isLessThanOrEqualTo: searchQuery + '\uf8ff');
    }

    switch (sortBy) {
      case 'viewCount':
        query = query.orderBy('viewCount', descending: true);
        break;
      case 'likeCount':
        query = query.orderBy('likeCount', descending: true);
        break;
      case 'createdAt':
      default:
        query = query.orderBy('createdAt', descending: true);
        break;
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => CommunityPost.fromFirestore(doc)).toList();
    });
  }

  Stream<CommunityPost> getPost(String postId) {
    return _firestore.collection('posts').doc(postId).snapshots().map((doc) => CommunityPost.fromFirestore(doc));
  }

  Future<void> createPost({
    required String title,
    required String content,
    required String authorId,
    required String authorName,
    List<File> images = const [],
  }) async {
    try {
      List<String> imageUrls = [];
      if (images.isNotEmpty) {
        for (var image in images) {
          final ref = _storage.ref().child('community_images/${DateTime.now().toIso8601String()}');
          await ref.putFile(image);
          imageUrls.add(await ref.getDownloadURL());
        }
      }

      await _firestore.collection('posts').add({
        'title': title,
        'content': content,
        'authorId': authorId,
        'authorName': authorName,
        'createdAt': FieldValue.serverTimestamp(),
        'viewCount': 0,
        'likeCount': 0,
        'imageUrls': imageUrls,
        'likedBy': [],
      });
    } catch (e) {
      print(e);
      rethrow;
    }
  }
  
  Future<void> updatePost(String postId, String title, String content) async {
    await _firestore.collection('posts').doc(postId).update({
      'title': title,
      'content': content,
    });
  }

  Future<void> deletePost(String postId) async {
    await _firestore.collection('posts').doc(postId).delete();
  }

  Future<void> incrementViewCount(String postId) {
    return _firestore.collection('posts').doc(postId).update({'viewCount': FieldValue.increment(1)});
  }

  // Comment Methods
  Stream<List<CommunityComment>> getComments(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => CommunityComment.fromFirestore(doc)).toList();
    });
  }

  Future<void> addComment({
    required String postId,
    required String content,
    required String authorId,
    required String authorName,
    String? parentId,
  }) async {
    await _firestore.collection('posts').doc(postId).collection('comments').add({
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': FieldValue.serverTimestamp(),
      'likeCount': 0,
      'parentId': parentId,
      'likedBy': [],
    });
  }

  // Like/Dislike Methods
  Future<void> togglePostLike(String postId, String userId) async {
    final postRef = _firestore.collection('posts').doc(postId);
    final postDoc = await postRef.get();

    if (postDoc.exists) {
      List<String> likedBy = List<String>.from(postDoc.data()!['likedBy'] ?? []);
      if (likedBy.contains(userId)) {
        postRef.update({
          'likeCount': FieldValue.increment(-1),
          'likedBy': FieldValue.arrayRemove([userId]),
        });
      } else {
        postRef.update({
          'likeCount': FieldValue.increment(1),
          'likedBy': FieldValue.arrayUnion([userId]),
        });
      }
    }
  }
  
  Future<void> toggleCommentLike(String postId, String commentId, String userId) async {
    final commentRef = _firestore.collection('posts').doc(postId).collection('comments').doc(commentId);
    final commentDoc = await commentRef.get();

    if (commentDoc.exists) {
      List<String> likedBy = List<String>.from(commentDoc.data()!['likedBy'] ?? []);
      if (likedBy.contains(userId)) {
        commentRef.update({
          'likeCount': FieldValue.increment(-1),
          'likedBy': FieldValue.arrayRemove([userId]),
        });
      } else {
        commentRef.update({
          'likeCount': FieldValue.increment(1),
          'likedBy': FieldValue.arrayUnion([userId]),
        });
      }
    }
  }
}
