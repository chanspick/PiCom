
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../models/user_model.dart';
import '../../models/post_model.dart';
import '../../models/listing_model.dart';
import '../../models/part_model.dart';
import '../../services/listing_service.dart';
import '../product/listing_detail_screen.dart';
import '../product/part_shop_screen.dart';
import '../product/sell_request_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ListingService _listingService = ListingService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
                    _buildPostsGrid(user.id),
                    const Center(child: Text('보관함 내용')), // Placeholder
                    _HistoryListView(stream: _listingService.getMyPurchaseHistory(user.id), isPurchaseHistory: true),
                    _HistoryListView(stream: _listingService.getMySalesHistory(user.id), isPurchaseHistory: false),
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
    // ... (This widget remains the same)
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: user.photoURL.isNotEmpty ? NetworkImage(user.photoURL) : null,
            child: user.photoURL.isEmpty ? const Icon(Icons.person, size: 50) : null,
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
                  Text(user.followers.length.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Text('팔로워', style: TextStyle(color: Colors.grey)),
                ],
              ),
              const SizedBox(width: 24),
              Column(
                children: [
                  Text(user.following.length.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Text('팔로잉', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!isCurrentUser)
            ElevatedButton(
              onPressed: () {},
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
    // ... (This widget remains mostly the same)
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('posts').where('userId', isEqualTo: userId).orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) return const Center(child: Text('게시물이 없습니다.'));

        final posts = snapshot.data!.docs.map((doc) => PostModel.fromFirestore(doc)).toList();

        return GridView.builder(
          padding: const EdgeInsets.all(4),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 4, mainAxisSpacing: 4),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return Image.network(post.imageUrl, fit: BoxFit.cover);
          },
        );
      },
    );
  }
}

class _HistoryListView extends StatelessWidget {
  final Stream<List<Listing>> stream;
  final bool isPurchaseHistory;

  const _HistoryListView({required this.stream, required this.isPurchaseHistory});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');

    return StreamBuilder<List<Listing>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('내역을 불러오는 중 오류가 발생했습니다: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(context);
        }

        final listings = snapshot.data!;
        return ListView.builder(
          itemCount: listings.length,
          itemBuilder: (context, index) {
            final listing = listings[index];
            final date = isPurchaseHistory ? listing.soldAt : listing.createdAt;
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: listing.imageUrls.isNotEmpty ? NetworkImage(listing.imageUrls.first) : null,
                child: listing.imageUrls.isEmpty ? const Icon(Icons.image) : null,
              ),
              title: FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('parts').doc(listing.partId).get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text('...');
                  }
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Text('부품 정보 없음');
                  }
                  final part = Part.fromFirestore(snapshot.data!);
                  return Text(part.modelName);
                },
              ),
              subtitle: Text('${formatter.format(listing.price)}원'),
              trailing: Text(date != null ? DateFormat('yy/MM/dd').format(date) : 'N/A'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ListingDetailScreen(listingId: listing.listingId)), // Changed from listing.id to listing.listingId
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(isPurchaseHistory ? '구매 내역이 없습니다.' : '판매 내역이 없습니다.'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => isPurchaseHistory ? const PartShopScreen() : const SellRequestScreen()),
              );
            },
            child: Text(isPurchaseHistory ? '구매하러 가기' : '판매 요청하기'),
          ),
        ],
      ),
    );
  }
}
