import 'package:flutter/material.dart';
import 'package:picom/models/part_comment_model.dart';
import 'package:picom/services/part_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class PartCommentScreen extends StatefulWidget {
  final String partId;
  const PartCommentScreen({super.key, required this.partId});

  @override
  State<PartCommentScreen> createState() => _PartCommentScreenState();
}

class _PartCommentScreenState extends State<PartCommentScreen> {
  final PartService _partService = PartService();
  final _commentController = TextEditingController();
  final _currentUser = FirebaseAuth.instance.currentUser;
  String _sortBy = 'createdAt';

  void _postComment({String? parentId}) {
    if (_commentController.text.isEmpty || _currentUser == null) return;

    _partService.addPartComment(
      partId: widget.partId,
      content: _commentController.text,
      authorId: _currentUser!.uid,
      authorName: _currentUser!.displayName ?? 'Anonymous',
      parentId: parentId,
    );
    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('부품 댓글'),
        actions: [
          DropdownButton<String>(
            value: _sortBy,
            items: const [
              DropdownMenuItem(value: 'createdAt', child: Text('등록순')),
              DropdownMenuItem(value: 'likes', child: Text('추천순')),
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
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<PartComment>>(
              stream: _partService.getPartComments(widget.partId, sortBy: _sortBy),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('댓글이 없습니다.'));
                }

                final comments = snapshot.data!;
                final commentTree = _buildCommentTree(comments);

                return ListView.builder(
                  itemCount: commentTree.length,
                  itemBuilder: (context, index) {
                    final comment = commentTree[index];
                    return _CommentCard(
                      partId: widget.partId,
                      comment: comment,
                      replies: _getReplies(comment.id, comments),
                      partService: _partService,
                      currentUser: _currentUser,
                    );
                  },
                );
              },
            ),
          ),
          _buildCommentInputField(),
        ],
      ),
    );
  }

  List<PartComment> _buildCommentTree(List<PartComment> comments) {
    return comments.where((c) => c.parentId == null).toList();
  }

  List<PartComment> _getReplies(String commentId, List<PartComment> allComments) {
    return allComments.where((c) => c.parentId == commentId).toList();
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
          IconButton(icon: const Icon(Icons.send), onPressed: () => _postComment()),
        ],
      ),
    );
  }
}

class _CommentCard extends StatefulWidget {
  final String partId;
  final PartComment comment;
  final List<PartComment> replies;
  final PartService partService;
  final User? currentUser;

  const _CommentCard({
    required this.partId,
    required this.comment,
    required this.replies,
    required this.partService,
    required this.currentUser,
  });

  @override
  State<_CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<_CommentCard> {
  bool _isReplying = false;
  final _replyController = TextEditingController();

  void _postReply() {
    if (_replyController.text.isEmpty || widget.currentUser == null) return;

    widget.partService.addPartComment(
      partId: widget.partId,
      content: _replyController.text,
      authorId: widget.currentUser!.uid,
      authorName: widget.currentUser!.displayName ?? 'Anonymous',
      parentId: widget.comment.id,
    );
    _replyController.clear();
    setState(() {
      _isReplying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLiked = widget.currentUser != null && widget.comment.likedBy.contains(widget.currentUser!.uid);
    final isAuthor = widget.currentUser?.uid == widget.comment.authorId;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(widget.comment.authorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Text(
                  DateFormat('yyyy-MM-dd').format(widget.comment.createdAt.toDate()),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const Spacer(),
                if (isAuthor)
                  IconButton(
                    icon: const Icon(Icons.delete, size: 16),
                    onPressed: () {
                      widget.partService.deletePartComment(partId: widget.partId, commentId: widget.comment.id);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(widget.comment.content),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isReplying = !_isReplying;
                    });
                  },
                  child: const Text('답글'),
                ),
                TextButton.icon(
                  onPressed: () {
                    if (widget.currentUser != null) {
                      widget.partService.togglePartCommentLike(
                        partId: widget.partId,
                        commentId: widget.comment.id,
                        userId: widget.currentUser!.uid,
                      );
                    }
                  },
                  icon: Icon(
                    isLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                    size: 16,
                    color: isLiked ? Colors.blue : Colors.grey,
                  ),
                  label: Text(widget.comment.likes.toString()),
                ),
              ],
            ),
            if (_isReplying)
              Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _replyController,
                        decoration: const InputDecoration(hintText: '답글을 입력하세요...'),
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.send), onPressed: _postReply),
                  ],
                ),
              ),
            if (widget.replies.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                child: Column(
                  children: widget.replies.map((reply) {
                    return _CommentCard(
                      partId: widget.partId,
                      comment: reply,
                      replies: const [], // Replies are not nested further in this simple implementation
                      partService: widget.partService,
                      currentUser: widget.currentUser,
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
