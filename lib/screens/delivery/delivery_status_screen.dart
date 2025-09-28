
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// 주문 상태를 나타내는 Enum
enum DeliveryStatus {
  preparing, // 배송 준비중
  shipping,  // 배송중
  delivered, // 배송 완료
}

// 임시 주문 데이터 모델
class Order {
  final String orderId;
  final String productName;
  final DateTime orderDate;
  final DeliveryStatus status;
  final String imageUrl;

  Order({
    required this.orderId,
    required this.productName,
    required this.orderDate,
    required this.status,
    required this.imageUrl,
  });
}

class DeliveryStatusScreen extends StatefulWidget {
  const DeliveryStatusScreen({super.key});

  @override
  State<DeliveryStatusScreen> createState() => _DeliveryStatusScreenState();
}

class _DeliveryStatusScreenState extends State<DeliveryStatusScreen> {
  // 실시간 데이터 연동 전 사용할 임시 데이터
  final List<Order> _orders = [
    Order(orderId: '20240520-001', productName: '정품 라이트닝 케이블', orderDate: DateTime(2024, 5, 20), status: DeliveryStatus.delivered, imageUrl: 'https://via.placeholder.com/150'),
    Order(orderId: '20240521-002', productName: '고속 충전 어댑터', orderDate: DateTime(2024, 5, 21), status: DeliveryStatus.shipping, imageUrl: 'https://via.placeholder.com/150'),
    Order(orderId: '20240522-003', productName: '맥세이프 케이스', orderDate: DateTime(2024, 5, 22), status: DeliveryStatus.preparing, imageUrl: 'https://via.placeholder.com/150'),
    Order(orderId: '20240522-004', productName: '애플워치 스트랩', orderDate: DateTime(2024, 5, 22), status: DeliveryStatus.preparing, imageUrl: 'https://via.placeholder.com/150'),
  ];

  // TODO: 추후 Firestore와 연동하여 실시간 주문 목록을 가져오는 로직 구현

  String _statusToString(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.preparing:
        return '배송 준비중';
      case DeliveryStatus.shipping:
        return '배송중';
      case DeliveryStatus.delivered:
        return '배송 완료';
    }
  }

  IconData _statusToIcon(DeliveryStatus status) {
     switch (status) {
      case DeliveryStatus.preparing:
        return Icons.inventory_2_outlined;
      case DeliveryStatus.shipping:
        return Icons.local_shipping_outlined;
      case DeliveryStatus.delivered:
        return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar는 ProfileScreen의 TabBarView 안에 있으므로 여기서는 불필요합니다.
      body: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          final order = _orders[index];
          return _buildStatusCard(order);
        },
      ),
    );
  }

  Widget _buildStatusCard(Order order) {
    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Container(
                width: 70,
                height: 70,
                color: Colors.grey[200],
                child: const Icon(
                  Icons.photo_size_select_actual_outlined,
                  color: Colors.grey,
                  size: 35,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.productName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '주문일자: ${DateFormat('yyyy.MM.dd').format(order.orderDate)}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(_statusToIcon(order.status), color: Theme.of(context).primaryColor, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        _statusToString(order.status),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
