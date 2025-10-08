
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/order_model.dart' as app_order;
import '../../services/order_service.dart';

class DeliveryStatusScreen extends StatefulWidget {
  const DeliveryStatusScreen({super.key});

  @override
  State<DeliveryStatusScreen> createState() => _DeliveryStatusScreenState();
}

class _DeliveryStatusScreenState extends State<DeliveryStatusScreen> {
  final OrderService _orderService = OrderService();
  late Future<List<app_order.Order>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _orderService.getOrdersForCurrentUser();
  }

  String _statusToString(app_order.DeliveryStatus status) {
    switch (status) {
      case app_order.DeliveryStatus.preparing:
        return '배송 준비중';
      case app_order.DeliveryStatus.shipping:
        return '배송중';
      case app_order.DeliveryStatus.delivered:
        return '배송 완료';
    }
  }

  IconData _statusToIcon(app_order.DeliveryStatus status) {
    switch (status) {
      case app_order.DeliveryStatus.preparing:
        return Icons.inventory_2_outlined;
      case app_order.DeliveryStatus.shipping:
        return Icons.local_shipping_outlined;
      case app_order.DeliveryStatus.delivered:
        return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<app_order.Order>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('오류가 발생했습니다: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('주문 내역이 없습니다.'));
          }

          final orders = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return _buildStatusCard(order);
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(app_order.Order order) {
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
              child: order.imageUrl.isNotEmpty
                  ? Image.network(
                      order.imageUrl,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 70,
                          height: 70,
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.grey,
                            size: 35,
                          ),
                        );
                      },
                    )
                  : Container(
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
                    '${NumberFormat('#,###').format(order.price)}원',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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
