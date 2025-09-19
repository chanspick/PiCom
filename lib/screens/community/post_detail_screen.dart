import 'package:flutter/material.dart';
import 'package:picom/models/community_post_model.dart';
import 'package:picom/models/community_comment_model.dart';
import 'package:picom/services/community_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final CommunityService _communityService = CommunityService();
  final _commentController = TextEditingController();
  final _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _communityService.incrementViewCount(widget.postId);
  }

  void _postComment() {
    if (_commentController.text.isEmpty || _currentUser == null) return;

    _communityService.addComment(
      postId: widget.postId,
      content: _commentController.text,
      authorId: _currentUser!.uid,
      authorName: _currentUser!.displayName ?? 'Anonymous',
    );
    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('게시물')),
      body: StreamBuilder<CommunityPost>(
        stream: _communityService.getPost(widget.postId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
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
                      const SizedBox(height: 8),
                      Text('By ${post.authorName}', style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 16),
                      Text(post.content, style: Theme.of(context).textTheme.bodyLarge),
                      // TODO: Display images
                      const SizedBox(height: 16),
                      _buildLikeButton(post),
                      const Divider(height: 32),
                      Text('댓글', style: Theme.of(context).textTheme.titleLarge),
                      _buildCommentList(),
                    ],
                  ),
                ),
              ),
              _buildCommentInputField(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLikeButton(CommunityPost post) {
    final isLiked = _currentUser != null && post.likedBy.contains(_currentUser!.uid);
    return ElevatedButton.icon(
      icon: Icon(isLiked ? Icons.thumb_up : Icons.thumb_up_outlined),
      label: Text('추천 ${post.likeCount}'),
      onPressed: () {
        if (_currentUser != null) {
          _communityService.togglePostLike(post.id, _currentUser!.uid);
        }
      },
    );
  }

  Widget _buildCommentList() {
    return StreamBuilder<List<CommunityComment>>(
      stream: _communityService.getComments(widget.postId),
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
              // TODO: Add comment like button and reply functionality
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
