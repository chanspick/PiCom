import 'package:flutter/material.dart';
import 'package:picom/models/qna_post_model.dart';
import 'package:picom/services/qna_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QnaWriteScreen extends StatefulWidget {
  final QnaService qnaService;

  const QnaWriteScreen({super.key, required this.qnaService});

  @override
  State<QnaWriteScreen> createState() => _QnaWriteScreenState();
}

class _QnaWriteScreenState extends State<QnaWriteScreen> {
  final _formKey = GlobalKey<FormState>();
  QnaCategory _selectedCategory = QnaCategory.app;
  bool _isPrivate = false;
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QnA 작성'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null || user.isAnonymous) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('글을 작성하려면 로그인이 필요합니다.')),
                  );
                  return;
                }

                final newPost = QnaPost(
                  id: '', // Will be set by the service
                  category: _selectedCategory,
                  title: _titleController.text,
                  content: _contentController.text,
                  isPrivate: _isPrivate,
                  authorId: user.uid,
                  authorNickname: user.displayName ?? 'Anonymous',
                );

                try {
                  await widget.qnaService.addPost(newPost);
                  Navigator.of(context).pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('게시글 작성에 실패했습니다: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<QnaCategory>(
                value: _selectedCategory,
                items: QnaCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category.koreanName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }
                },
                decoration: const InputDecoration(
                  labelText: '분류',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '제목',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '제목을 입력하세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: '내용',
                  border: OutlineInputBorder(),
                ),
                maxLines: 10,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '내용을 입력하세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('비공개'),
                value: _isPrivate,
                onChanged: (value) {
                  setState(() {
                    _isPrivate = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
