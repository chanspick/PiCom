import 'package:cloud_firestore/cloud_firestore.dart';

class PartComment {
  final String id;
  final String content;
  final String authorId;
  final String authorName;
  final Timestamp createdAt;
  final int likes;
  final List<String> likedBy;
  final String? parentId;

  PartComment({
    required this.id,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.likes = 0,
    this.likedBy = const [],
    this.parentId,
  });

  factory PartComment.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return PartComment(
      id: doc.id,
      content: data['content'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      likes: data['likes'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      parentId: data['parentId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': createdAt,
      'likes': likes,
      'likedBy': likedBy,
      'parentId': parentId,
    };
  }
}
