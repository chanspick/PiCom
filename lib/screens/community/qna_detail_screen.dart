import 'package:flutter/material.dart';
import 'package:picom/models/qna_post_model.dart';
import 'package:picom/models/community_comment_model.dart';
import 'package:picom/services/auth_service.dart';
import 'package:picom/services/qna_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QnaDetailScreen extends StatefulWidget {
  final String postId;
  const QnaDetailScreen({super.key, required this.postId});

  @override
  State<QnaDetailScreen> createState() => _QnaDetailScreenState();
}

class _QnaDetailScreenState extends State<QnaDetailScreen> {
  final QnaService _qnaService = QnaService();
  final AuthService _authService = AuthService();
  final _commentController = TextEditingController();
  final _currentUser = FirebaseAuth.instance.currentUser;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    // _qnaService.incrementViewCount(widget.postId); // TODO: Implement view count
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

  void _postComment() async {
    if (_commentController.text.isEmpty || _currentUser == null) return;

    // Force refresh the token to get the latest custom claims.
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.getIdTokenResult(true);
      print('관리자 토큰 새로고침 완료');
    }

    await _qnaService.addComment(
      postId: widget.postId,
      content: _commentController.text,
      authorId: _currentUser!.uid,
      authorName: _currentUser!.displayName ?? 'Admin',
    );
    _commentController.clear();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('')),
      body: StreamBuilder<QnaPost>(
        stream: _qnaService.getPostStream(widget.postId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Post not found.'));
          }
          final post = snapshot.data!;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.title, style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 16),
                      Text(post.content, style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: 16),
                      _buildLikeButton(post),
                      const Divider(height: 32),
                      Text('댓글', style: Theme.of(context).textTheme.titleLarge),
                      _buildCommentList(),
                    ],
                  ),
                ),
              ),
              if (_isAdmin) _buildCommentInputField(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLikeButton(QnaPost post) {
    final isLiked = _currentUser != null && post.likedBy.contains(_currentUser!.uid);
    return ElevatedButton.icon(
      icon: Icon(isLiked ? Icons.thumb_up : Icons.thumb_up_outlined),
      label: Text('추천 ${post.likes}'),
      onPressed: () {
        if (_currentUser != null) {
          _qnaService.togglePostLike(post.id, _currentUser!.uid);
        }
      },
    );
  }

  Widget _buildCommentList() {
    return StreamBuilder<List<CommunityComment>>(
      stream: _qnaService.getComments(widget.postId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final comments = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: comments.length,
          itemBuilder: (context, index) {
            final comment = comments[index];
            return ListTile(
              title: Text(comment.content),
              subtitle: Text(comment.authorName),
            );
          },
        );
      },
    );
  }

  Widget _buildCommentInputField() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: const InputDecoration(hintText: '댓글을 입력하세요...'),
            ),
          ),
          IconButton(icon: const Icon(Icons.send), onPressed: _postComment),
        ],
      ),
    );
  }
}
