import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class InquiryDetailScreen extends StatefulWidget {
  final String inquiryId;

  const InquiryDetailScreen({super.key, required this.inquiryId});

  @override
  State<InquiryDetailScreen> createState() => _InquiryDetailScreenState();
}

class _InquiryDetailScreenState extends State<InquiryDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    _isAdmin = await _authService.isAdmin();
    setState(() {});
  }

  Future<void> _addComment(String inquiryId) async {
    if (_commentController.text.trim().isEmpty) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
      }
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('inquiries')
          .doc(inquiryId)
          .collection('comments')
          .add({
            'content': _commentController.text.trim(),
            'authorId': user.uid,
            'authorName': user.displayName ?? '운영자', // 운영자만 댓글 가능하므로 기본값 운영자
            'createdAt': Timestamp.now(),
            'isAdmin': true, // 운영자 댓글임을 명시
          });
      if (mounted) {
        _commentController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('댓글 추가 중 오류 발생: $e')));
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('문의 상세')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('inquiries')
                    .doc(widget.inquiryId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('오류: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Center(child: Text('문의를 찾을 수 없습니다.'));
                  }

                  final inquiryData =
                      snapshot.data!.data() as Map<String, dynamic>;
                  final title = inquiryData['title'] ?? '제목 없음';
                  final content = inquiryData['content'] ?? '내용 없음';
                  final authorName = inquiryData['authorName'] ?? '익명';
                  final createdAt = (inquiryData['createdAt'] as Timestamp)
                      .toDate();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '작성자: $authorName | ${createdAt.toLocal().toString().split(' ')[0]}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const Divider(height: 24),
                      Text(content, style: const TextStyle(fontSize: 16)),
                      const Divider(height: 24),
                      const Text(
                        '답변',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('inquiries')
                            .doc(widget.inquiryId)
                            .collection('comments')
                            .orderBy('createdAt')
                            .snapshots(),
                        builder: (context, commentSnapshot) {
                          if (commentSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (commentSnapshot.hasError) {
                            return Center(
                              child: Text('댓글 로드 오류: ${commentSnapshot.error}'),
                            );
                          }
                          if (!commentSnapshot.hasData ||
                              commentSnapshot.data!.docs.isEmpty) {
                            return const Text('아직 답변이 없습니다.');
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: commentSnapshot.data!.docs.length,
                            itemBuilder: (context, index) {
                              final commentData =
                                  commentSnapshot.data!.docs[index].data()
                                      as Map<String, dynamic>;
                              final commentContent =
                                  commentData['content'] ?? '내용 없음';
                              final commentAuthor =
                                  commentData['authorName'] ?? '운영자';
                              final commentCreatedAt =
                                  (commentData['createdAt'] as Timestamp)
                                      .toDate();

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4.0,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$commentAuthor | ${commentCreatedAt.toLocal().toString().split(' ')[0]}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(commentContent),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          // 운영자만 댓글 입력 가능
          if (_isAdmin)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: '답변을 입력하세요...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: null,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () => _addComment(widget.inquiryId),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
