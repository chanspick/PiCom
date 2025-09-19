import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityPost {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final Timestamp createdAt;
  final int viewCount;
  final int likeCount;
  final List<String> imageUrls;
  final List<String> likedBy;

  CommunityPost({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    required this.viewCount,
    required this.likeCount,
    required this.imageUrls,
    required this.likedBy,
  });

  factory CommunityPost.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return CommunityPost(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      viewCount: data['viewCount'] ?? 0,
      likeCount: data['likeCount'] ?? 0,
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      likedBy: List<String>.from(data['likedBy'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': createdAt,
      'viewCount': viewCount,
      'likeCount': likeCount,
      'imageUrls': imageUrls,
      'likedBy': likedBy,
    };
  }
}
