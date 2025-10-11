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
  // [수정] Future -> Stream으로 변경
  late Stream<List<OrderModel>> _ordersStream;

  @override
  void initState() {
    super.initState();
    // [수정] Stream을 구독하도록 변경
    _ordersStream = _orderService.getOrdersForCurrentUser();
  }

  // [전면 재작성] 새로운 OrderStatus Enum에 맞춰 텍스트 반환
  String _statusToString(OrderStatus status) {
    switch (status) {
      case OrderStatus.paymentComplete:
        return '결제 완료';
      case OrderStatus.awaitingSellerShipment:
        return '판매자 발송 대기';
      case OrderStatus.partiallyArrived:
        return '부분 입고';
      case OrderStatus.allItemsArrived:
        return '전체 입고';
      case OrderStatus.inspecting:
        return '플랫폼 검수중';
      case OrderStatus.assembling:
        return '조립중';
      case OrderStatus.shippedToBuyer:
        return '배송중';
      case OrderStatus.delivered:
        return '배송 완료';
      case OrderStatus.completed:
        return '구매 확정';
      case OrderStatus.cancelled:
        return '주문 취소';
    }
  }

  // [전면 재작성] 새로운 OrderStatus Enum에 맞춰 아이콘 반환
  IconData _statusToIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.paymentComplete:
        return Icons.credit_card;
      case OrderStatus.awaitingSellerShipment:
        return Icons.forward_to_inbox_outlined;
      case OrderStatus.partiallyArrived:
        return Icons.rule_folder_outlined;
      case OrderStatus.allItemsArrived:
        return Icons.inventory_2_outlined;
      case OrderStatus.inspecting:
        return Icons.fact_check_outlined;
      case OrderStatus.assembling:
        return Icons.build_circle_outlined;
      case OrderStatus.shippedToBuyer:
        return Icons.local_shipping_outlined;
      case OrderStatus.delivered:
        return Icons.check_circle_outline;
      case OrderStatus.completed:
        return Icons.verified_outlined;
      case OrderStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // [수정] FutureBuilder -> StreamBuilder로 변경
      body: StreamBuilder<List<OrderModel>>(
        stream: _ordersStream,
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
    // [수정] productName -> modelName 으로 변경
    final representativeItemName = order.items.isNotEmpty ? order.items.first.modelName : '상품 정보 없음';
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
                  // [수정] orderDate -> createdAt 으로 변경
                  '주문일자: ${DateFormat('yyyy.MM.dd').format(order.createdAt.toDate())}',
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