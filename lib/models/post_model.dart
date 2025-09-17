import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String userId;
  final String imageUrl;
  final int likes;
  final int comments;
  final Timestamp createdAt;

  PostModel({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.likes,
    required this.comments,
    required this.createdAt,
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      likes: data['likes'] ?? 0,
      comments: data['comments'] ?? 0,
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }
}
