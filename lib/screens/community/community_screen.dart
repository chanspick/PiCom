import 'package:flutter/material.dart';
import 'package:picom/models/qna_post_model.dart';
import 'package:picom/services/auth_service.dart';
import 'package:picom/services/qna_service.dart';
import 'package:picom/screens/community/qna_write_screen.dart';
import 'package:picom/screens/community/qna_detail_screen.dart';
import 'package:intl/intl.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final QnaService _qnaService = QnaService();
  final AuthService _authService = AuthService();
  QnaCategory? _selectedCategory;
  String _sortBy = 'createdAt';
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await _authService.isAdmin();
    if (mounted) {
      setState(() {
        _isAdmin = isAdmin;
      });
    }
  }

  void _refresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QnA'),
      ),
      body: Column(
        children: [
          _buildFilterAndSort(),
          Expanded(
            child: StreamBuilder<List<QnaPost>>(
              stream: _qnaService.getPosts(category: _selectedCategory, sortBy: _sortBy),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('오류: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('게시물이 없습니다. 첫 번째 게시물을 작성해보세요!'));
                }

                final posts = snapshot.data!;
                final filteredPosts = _isAdmin ? posts : posts.where((post) => !post.isPrivate).toList();

                if (filteredPosts.isEmpty) {
                  return const Center(child: Text('표시할 게시물이 없습니다.'));
                }

                return ListView.builder(
                  itemCount: filteredPosts.length,
                  itemBuilder: (context, index) {
                    return _QnaPostCard(
                      post: filteredPosts[index],
                      isAdmin: _isAdmin,
                      qnaService: _qnaService,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => QnaWriteScreen(qnaService: _qnaService)),
          );
          _refresh(); // Refresh the list after returning from the write screen
        },
        child: const Icon(Icons.create),
      ),
    );
  }

  Widget _buildFilterAndSort() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          DropdownButton<QnaCategory?>(
            value: _selectedCategory,
            hint: const Text('전체'),
            items: [
              const DropdownMenuItem(value: null, child: Text('전체')),
              ...QnaCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category.koreanName),
                );
              }),
            ],
            onChanged: (value) {
              setState(() {
                _selectedCategory = value;
              });
            },
          ),
          const Spacer(),
          DropdownButton<String>(
            value: _sortBy,
            items: const [
              DropdownMenuItem(value: 'createdAt', child: Text('등록순')),
              DropdownMenuItem(value: 'likeCount', child: Text('추천순')),
              DropdownMenuItem(value: 'viewCount', child: Text('조회순')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _sortBy = value;
                });
              }
            },
          ),
        ],
      ),
    );
  }
}

class _QnaPostCard extends StatelessWidget {
  final QnaPost post;
  final bool isAdmin;
  final QnaService qnaService;

  const _QnaPostCard({required this.post, required this.isAdmin, required this.qnaService});

  @override
  Widget build(BuildContext context) {
    final isPrivate = post.isPrivate;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QnaDetailScreen(postId: post.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '[${post.category.koreanName}]',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (isAdmin && post.status == QnaStatus.pending)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                      ),
                      onPressed: () {
                        qnaService.updatePostStatus(post.id, QnaStatus.answered);
                      },
                      child: const Text('답변 완료', style: TextStyle(fontSize: 12)),
                    )
                  else
                    Text(
                      post.status == QnaStatus.answered ? '답변 완료' : '답변 대기',
                      style: TextStyle(
                        color: post.status == QnaStatus.answered ? Colors.blue : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                isPrivate ? '비공개 게시글입니다.' : post.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(isPrivate ? '비공개' : post.authorNickname, style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('yyyy-MM-dd').format(post.createdAt.toDate()),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const Spacer(),
                  const Icon(Icons.thumb_up_alt_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(isPrivate ? '-' : post.likes.toString(), style: const TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}