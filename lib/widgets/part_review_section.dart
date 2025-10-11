
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/part_review_model.dart';
import '../services/firestore_service.dart'; // 서비스 파일 경로에 맞게 수정
import './review_card.dart';

class PartReviewSection extends StatefulWidget {
  final String partId;

  const PartReviewSection({Key? key, required this.partId}) : super(key: key);

  @override
  _PartReviewSectionState createState() => _PartReviewSectionState();
}

class _PartReviewSectionState extends State<PartReviewSection> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _reviewController = TextEditingController();
  final FocusNode _reviewFocusNode = FocusNode();
  String _orderBy = 'createdAt'; // 기본 정렬: 등록순

  void _addReview() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // 로그인 필요 알림
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('리뷰를 작성하려면 로그인이 필요합니다.')),
      );
      return;
    }

    if (_reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('리뷰 내용을 입력해주세요.')),
      );
      return;
    }

    final newReview = PartReview(
      id: '', // ID는 Firestore에서 자동 생성
      partId: widget.partId,
      userId: user.uid,
      userName: user.displayName ?? 'Anonymous', // 사용자 이름이 없다면 'Anonymous'
      content: _reviewController.text.trim(),
      createdAt: Timestamp.now(),
      likes: [],
      dislikes: [],
    );

    _firestoreService.addReview(newReview).then((_) {
      _reviewController.clear();
      _reviewFocusNode.unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('리뷰가 등록되었습니다.')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류가 발생했습니다: $error')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets, // 키보드가 올라올 때 UI가 가려지지 않도록
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75, // 화면의 75% 높이
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 필터
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ChoiceChip(
                  label: const Text('등록순'),
                  selected: _orderBy == 'createdAt',
                  onSelected: (selected) {
                    if (selected) setState(() => _orderBy = 'createdAt');
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('추천순'),
                  selected: _orderBy == 'likes',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _orderBy = 'likes');
                    }
                  },
                ),
              ],
            ),
            // 리뷰 목록
            Expanded(
              child: StreamBuilder<List<PartReview>>(
                stream: _firestoreService.getReviewsStream(widget.partId, orderBy: _orderBy),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('아직 리뷰가 없습니다. 첫 리뷰를 남겨보세요!'));
                  }

                  final reviews = snapshot.data!;
                  // 추천순 정렬 (클라이언트 측)
                  if (_orderBy == 'likes') {
                    reviews.sort((a, b) => b.likes.length.compareTo(a.likes.length));
                  }

                  return ListView.builder(
                    itemCount: reviews.length,
                    itemBuilder: (context, index) {
                      final review = reviews[index];
                      return ReviewCard(review: review, partId: widget.partId);
                    },
                  );
                },
              ),
            ),
            // 리뷰 입력 필드
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _reviewController,
                      focusNode: _reviewFocusNode,
                      decoration: const InputDecoration(
                        hintText: '자유롭게 의견을 공유해주세요.',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      minLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _addReview,
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
