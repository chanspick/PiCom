import 'package:cloud_firestore/cloud_firestore.dart';

enum QnaCategory { app, payment, etc }

extension QnaCategoryExtension on QnaCategory {
  String get koreanName {
    switch (this) {
      case QnaCategory.app:
        return '앱문의';
      case QnaCategory.payment:
        return '결제문의';
      case QnaCategory.etc:
        return '기타요청';
    }
  }
}

enum QnaStatus { pending, answered }

class QnaPost {
  final String id;
  final QnaCategory category;
  final String title;
  final String content;
  final String authorId;
  final String authorNickname;
  final Timestamp createdAt;
  final QnaStatus status;
  final int likes;
  final int viewCount;
  final bool isPrivate;
  final List<String> likedBy;

  QnaPost({
    required this.id,
    required this.category,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorNickname,
    Timestamp? createdAt,
    this.status = QnaStatus.pending,
    this.likes = 0,
    this.viewCount = 0,
    this.isPrivate = false,
    this.likedBy = const [],
  }) : this.createdAt = createdAt ?? Timestamp.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category.name,
      'title': title,
      'content': content,
      'authorId': authorId,
      'authorNickname': authorNickname,
      'createdAt': createdAt,
      'status': status.name,
      'likes': likes,
      'viewCount': viewCount,
      'isPrivate': isPrivate,
      'likedBy': likedBy,
    };
  }

  factory QnaPost.fromMap(Map<String, dynamic> map) {
    return QnaPost(
      id: map['id'] ?? '',
      category: QnaCategory.values.firstWhere((e) => e.name == map['category'], orElse: () => QnaCategory.etc),
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      authorId: map['authorId'] ?? '',
      authorNickname: map['authorNickname'] ?? map['authorName'] ?? '',
      createdAt: map['createdAt'] ?? Timestamp.now(),
      status: QnaStatus.values.firstWhere((e) => e.name == map['status'], orElse: () => QnaStatus.pending),
      likes: map['likes'] ?? 0,
      viewCount: map['viewCount'] ?? 0,
      isPrivate: map['isPrivate'] ?? false,
      likedBy: List<String>.from(map['likedBy'] ?? []),
    );
  }

  QnaPost copyWith({
    String? id,
    QnaCategory? category,
    String? title,
    String? content,
    String? authorId,
    String? authorNickname,
    Timestamp? createdAt,
    QnaStatus? status,
    int? likes,
    int? viewCount,
    bool? isPrivate,
    List<String>? likedBy,
  }) {
    return QnaPost(
      id: id ?? this.id,
      category: category ?? this.category,
      title: title ?? this.title,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      authorNickname: authorNickname ?? this.authorNickname,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      likes: likes ?? this.likes,
      viewCount: viewCount ?? this.viewCount,
      isPrivate: isPrivate ?? this.isPrivate,
      likedBy: likedBy ?? this.likedBy,
    );
  }
}
