import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/order_model.dart';
import '../../services/order_service.dart';

class DeliveryStatusScreen extends StatefulWidget {
  const DeliveryStatusScreen({super.key});

  @override
  State<DeliveryStatusScreen> createState() => _DeliveryStatusScreenState();
}

class _DeliveryStatusScreenState extends State<DeliveryStatusScreen> {
  final OrderService _orderService = OrderService();
  late Future<List<OrderModel>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _orderService.getOrdersForCurrentUser();
  }

  String _statusToString(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.processing:
        return '주문 처리중';
      case DeliveryStatus.preparing:
        return '배송 준비중';
      case DeliveryStatus.shipped:
        return '배송중';
      case DeliveryStatus.delivered:
        return '배송 완료';
      case DeliveryStatus.cancelled:
        return '주문 취소';
      case DeliveryStatus.returned:
        return '반품 완료';
    }
  }

  IconData _statusToIcon(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.processing:
        return Icons.pending_actions_outlined;
      case DeliveryStatus.preparing:
        return Icons.inventory_2_outlined;
      case DeliveryStatus.shipped:
        return Icons.local_shipping_outlined;
      case DeliveryStatus.delivered:
        return Icons.check_circle_outline;
      case DeliveryStatus.cancelled:
        return Icons.cancel_outlined;
      case DeliveryStatus.returned:
        return Icons.assignment_return_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<OrderModel>>(
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

  Widget _buildStatusCard(OrderModel order) {
    final representativeItemName = order.items.isNotEmpty ? order.items.first.productName : '상품 정보 없음';
    final extraItemsCount = order.items.length - 1;

    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '주문일자: ${DateFormat('yyyy.MM.dd').format(order.orderDate.toDate())}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
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
            const Divider(height: 20),
            Text(
              extraItemsCount > 0
                  ? '$representativeItemName 외 ${extraItemsCount}건'
                  : representativeItemName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${NumberFormat('#,###').format(order.finalTotal)}원',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}