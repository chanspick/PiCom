import 'package:flutter/material.dart';
import 'package:picom/models/community_post_model.dart';
import 'package:picom/services/community_service.dart';
import 'package:picom/screens/community/post_detail_screen.dart';
import 'package:picom/screens/community/create_edit_post_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final CommunityService _communityService = CommunityService();
  String _sortBy = 'createdAt';
  String? _searchQuery;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('커뮤니티'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final query = await showSearch<String>(context: context, delegate: PostSearchDelegate());
              setState(() {
                _searchQuery = query;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSortOptions(),
          Expanded(
            child: StreamBuilder<List<CommunityPost>>(
              stream: _communityService.getPosts(sortBy: _sortBy, searchQuery: _searchQuery),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('오류: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('게시물이 없습니다.'));
                }

                final posts = snapshot.data!;
                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return ListTile(
                      title: Text(post.title),
                      subtitle: Text(post.authorName),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('조회 ${post.viewCount}'),
                          Text('추천 ${post.likeCount}'),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PostDetailScreen(postId: post.id),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.create),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateEditPostScreen()));
        },
      ),
    );
  }

  Widget _buildSortOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          DropdownButton<String>(
            value: _sortBy,
            items: const [
              DropdownMenuItem(value: 'createdAt', child: Text('최신순')),
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

class PostSearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, ''));
  }

  @override
  Widget buildResults(BuildContext context) {
    close(context, query);
    return Container();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // You could build suggestions here based on recent searches, etc.
    return Container();
  }
}
