
import 'package:cloud_firestore/cloud_firestore.dart';

class PartReview {
  final String id;
  final String partId;
  final String userId;
  final String userName;
  final String content;
  final Timestamp createdAt;
  final List<String> likes; // 추천한 사용자 ID 목록
  final List<String> dislikes; // 비추천한 사용자 ID 목록

  PartReview({
    required this.id,
    required this.partId,
    required this.userId,
    required this.userName,
    required this.content,
    required this.createdAt,
    required this.likes,
    required this.dislikes,
  });

  // Firestore 데이터(Map)를 PartReview 객체로 변환
  factory PartReview.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PartReview(
      id: doc.id,
      partId: data['partId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Unknown User',
      content: data['content'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      likes: List<String>.from(data['likes'] ?? []),
      dislikes: List<String>.from(data['dislikes'] ?? []),
    );
  }

  // PartReview 객체를 Firestore 데이터(Map)로 변환
  Map<String, dynamic> toFirestore() {
    return {
      'partId': partId,
      'userId': userId,
      'userName': userName,
      'content': content,
      'createdAt': createdAt,
      'likes': likes,
      'dislikes': dislikes,
    };
  }
}
