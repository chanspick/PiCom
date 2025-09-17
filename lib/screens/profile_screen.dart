import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:picom/models/user_model.dart';
import 'package:picom/models/post_model.dart';
import 'package:picom/screens/sell_request_screen.dart'; // Added import

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // 탭 개수 4개로 변경
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Helper widget to display a single count
  Widget _buildCountDisplay(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildHistorySection(String userId, String collectionName) {
    return FutureBuilder<List<int>>(
      future: Future.wait([
        FirebaseFirestore.instance.collection(collectionName).where('userId', isEqualTo: userId).count().get().then((snapshot) => snapshot.count ?? 0),
        FirebaseFirestore.instance.collection(collectionName).where('userId', isEqualTo: userId).where('status', isEqualTo: 'in_progress').count().get().then((snapshot) => snapshot.count ?? 0),
        FirebaseFirestore.instance.collection(collectionName).where('userId', isEqualTo: userId).where('status', isEqualTo: 'completed').count().get().then((snapshot) => snapshot.count ?? 0),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('데이터를 불러오는 중 오류가 발생했습니다: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.length != 3) {
          return const Center(child: Text('데이터를 찾을 수 없습니다.'));
        }

        final total = snapshot.data![0];
        final inProgress = snapshot.data![1];
        final completed = snapshot.data![2];

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildCountDisplay('전체', total),
                  _buildCountDisplay('진행 중', inProgress),
                  _buildCountDisplay('종료', completed),
                ],
              ),
              // Add the Sales Request button here if it's the 'sales' collection
              if (collectionName == 'sales') ...[
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SellRequestScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50), // Full width button
                    backgroundColor: Colors.black, // Kream-like button style
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '판매요청',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('오류: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('사용자를 찾을 수 없습니다.'));
          }

          final user = UserModel.fromFirestore(snapshot.data!);
          final currentUser = FirebaseAuth.instance.currentUser;
          final isCurrentUser = currentUser?.uid == user.id;

          return Column(
            children: [
              _buildProfileHeader(user, isCurrentUser),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPostsGrid(user.id), // 게시물 탭
                    const Center(child: Text('보관함 내용')), // 보관함 탭
                    _buildHistorySection(user.id, 'purchases'), // 구매내역 탭
                    _buildHistorySection(user.id, 'sales'), // 판매내역 탭
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(UserModel user, bool isCurrentUser) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: user.photoURL.isNotEmpty
                ? NetworkImage(user.photoURL)
                : null,
            child: user.photoURL.isEmpty
                ? const Icon(Icons.person, size: 50)
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            user.displayName,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  Text(
                    user.followers.length.toString(),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Text('팔로워', style: TextStyle(color: Colors.grey)),
                ],
              ),
              const SizedBox(width: 24),
              Column(
                children: [
                  Text(
                    user.following.length.toString(),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Text('팔로잉', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!isCurrentUser) // 팔로우 버튼은 본인 프로필에서는 보이지 않음
            ElevatedButton(
              onPressed: () {
                // TODO: 팔로우/언팔로우 로직 구현
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('팔로우/언팔로우 기능은 아직 구현되지 않았습니다.')),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              child: const Text('팔로우'),
            ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      labelColor: Colors.black,
      unselectedLabelColor: Colors.grey,
      indicatorColor: Colors.black,
      tabs: const [
        Tab(text: '게시물'),
        Tab(text: '보관함'),
        Tab(text: '구매내역'),
        Tab(text: '판매내역'),
      ],
    );
  }

  Widget _buildPostsGrid(String userId) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          // Check for specific index error
          if (snapshot.error.toString().contains('requires an index')) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  '게시물을 불러올 수 없습니다. Firebase 콘솔에서 필요한 인덱스를 생성해주세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            );
          } else {
            // Generic error message
            return Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  '게시물을 불러오는 중 오류가 발생했습니다: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            );
          }
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('게시물이 없습니다.'));
        }

        final posts = snapshot.data!.docs.map((doc) => PostModel.fromFirestore(doc)).toList();

        return GridView.builder(
          padding: const EdgeInsets.all(4),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return GestureDetector(
              onTap: () {
                // TODO: 게시물 상세 페이지로 이동
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('게시물 ${post.id} 클릭됨')),
                );
              },
              child: Image.network(
                post.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, size: 30, color: Colors.grey),
                ),
              ),
            );
          },
        );
      },
    );
  }
}