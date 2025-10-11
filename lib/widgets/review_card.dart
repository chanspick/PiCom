
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/part_review_model.dart';
import '../services/firestore_service.dart'; // 서비스 파일 경로에 맞게 수정

class ReviewCard extends StatelessWidget {
  final PartReview review;
  final String partId;
  final FirestoreService _firestoreService = FirestoreService();

  ReviewCard({Key? key, required this.review, required this.partId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final bool isAuthor = currentUser != null && currentUser.uid == review.userId;
    final bool isLiked = currentUser != null && review.likes.contains(currentUser.uid);
    final bool isDisliked = currentUser != null && review.dislikes.contains(currentUser.uid);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  review.userName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (isAuthor)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.grey),
                    onPressed: () async {
                      // 삭제 확인 다이얼로그
                      final bool? confirm = await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('리뷰 삭제'),
                          content: const Text('정말로 이 리뷰를 삭제하시겠습니까?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('취소'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('삭제'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await _firestoreService.deleteReview(partId, review.id);
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(DateFormat('yyyy.MM.dd HH:mm').format(review.createdAt.toDate())),
            const SizedBox(height: 12),
            Text(review.content, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // 추천 기능
                            TextButton.icon(
                              onPressed: () {
                                if (currentUser != null) {
                                  _firestoreService.toggleLike(partId, review.id, currentUser.uid);
                                }
                              },
                              icon: Icon(
                                isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                                size: 18,
                                color: isLiked ? Theme.of(context).primaryColor : Colors.grey,
                              ),
                              label: Text('${review.likes.length}'),
                            ),
                            const SizedBox(width: 8),
                            // 비추천 기능
                            TextButton.icon(
                              onPressed: () {
                                if (currentUser != null) {
                                  _firestoreService.toggleDislike(partId, review.id, currentUser.uid);
                                }
                              },
                              icon: Icon(
                                isDisliked ? Icons.thumb_down : Icons.thumb_down_outlined,
                                size: 18,
                                color: isDisliked ? Colors.redAccent : Colors.grey,
                              ),
                              label: Text('${review.dislikes.length}'),
                            ),
                          ],
                        ),
          ],
        ),
      ),
    );
  }
}
