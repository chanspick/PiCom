import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../models/user_model.dart';
import '../../models/listing_model.dart';
import '../../models/part_model.dart';
import '../../models/order_model.dart' as order_model;
import '../../services/listing_service.dart';
import '../../services/order_service.dart';
import '../product/listing_detail_screen.dart';
import '../product/part_shop_screen.dart';
import '../product/sell_request_screen.dart';
import '../delivery/delivery_status_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ListingService _listingService = ListingService();
  final OrderService _orderService = OrderService(); // OrderService 추가

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text('내 정보'),
        elevation: 0,
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

          return Column(
            children: [
              _buildProfileHeader(user),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    const DeliveryStatusScreen(),
                    _OrderHistoryView(orderService: _orderService), // 구매내역 뷰 변경
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

  Widget _buildProfileHeader(UserModel user) {
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
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      tabs: const [
        Tab(text: '배송현황'),
        Tab(text: '구매내역'),
        Tab(text: '판매내역'),
      ],
    );
  }
}

// 새로운 주문 내역 뷰
class _OrderHistoryView extends StatelessWidget {
  final OrderService orderService;

  const _OrderHistoryView({required this.orderService});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<order_model.OrderModel>>(
      future: orderService.getOrdersForCurrentUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('주문 내역을 불러오는 중 오류가 발생했습니다: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('주문 내역이 없습니다.'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PartShopScreen()),
                    );
                  },
                  child: const Text('구매하러 가기'),
                ),
              ],
            ),
          );
        }

        final orders = snapshot.data!;
        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return _OrderHistoryCard(order: order);
          },
        );
      },
    );
  }
}

// 새로운 주문 내역 카드 위젯
class _OrderHistoryCard extends StatelessWidget {
  final order_model.OrderModel order;

  const _OrderHistoryCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');
    final representativeItem = order.items.isNotEmpty ? order.items.first.productName : '주문 정보 없음';
    final extraItemsCount = order.items.length - 1;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        title: Text(
          extraItemsCount > 0
              ? '$representativeItem 외 ${extraItemsCount}건'
              : representativeItem,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${formatter.format(order.finalTotal)}원'),
        trailing: Text(DateFormat('yy/MM/dd').format(order.orderDate.toDate())),
        onTap: () {
          // TODO: 주문 상세 화면으로 이동하는 로직 구현
          // Navigator.push(context, MaterialPageRoute(builder: (context) => OrderDetailScreen(orderId: order.orderId)));
        },
      ),
    );
  }
}

// 기존 판매 내역 뷰 (수정 없음)
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