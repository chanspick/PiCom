import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityComment {
  final String id;
  final String content;
  final String authorId;
  final String authorName;
  final Timestamp createdAt;
  final int likeCount;
  final String? parentId;
  final List<String> likedBy;

  CommunityComment({
    required this.id,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    required this.likeCount,
    this.parentId,
    required this.likedBy,
  });

  factory CommunityComment.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return CommunityComment(
      id: doc.id,
      content: data['content'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      likeCount: data['likeCount'] ?? 0,
      parentId: data['parentId'],
      likedBy: List<String>.from(data['likedBy'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': createdAt,
      'likeCount': likeCount,
      'parentId': parentId,
      'likedBy': likedBy,
    };
  }
}
