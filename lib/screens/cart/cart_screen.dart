import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// 임시 장바구니 상품 모델
class CartItem {
  final String id;
  final String productName;
  final String imageUrl;
  int quantity;
  final double price;

  CartItem({
    required this.id,
    required this.productName,
    required this.imageUrl,
    required this.quantity,
    required this.price,
  });
}

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // 임시 장바구니 데이터
  final List<CartItem> _cartItems = [
    CartItem(id: 'p001', productName: '정품 실리콘 케이스', imageUrl: 'https://via.placeholder.com/150', quantity: 1, price: 45000),
    CartItem(id: 'p002', productName: '가죽 스트랩', imageUrl: 'https://via.placeholder.com/150', quantity: 2, price: 65000),
    CartItem(id: 'p003', productName: '20W 고속 충전기', imageUrl: 'https://via.placeholder.com/150', quantity: 1, price: 28000),
  ];

  void _incrementQuantity(CartItem item) {
    setState(() {
      item.quantity++;
    });
  }

  void _decrementQuantity(CartItem item) {
    setState(() {
      if (item.quantity > 1) {
        item.quantity--;
      }
    });
  }

  void _removeItem(CartItem item) {
    setState(() {
      _cartItems.remove(item);
    });
  }

  double _calculateTotal() {
    return _cartItems.fold(0, (total, current) => total + (current.price * current.quantity));
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');

    return Scaffold(
      appBar: AppBar(
        title: const Text('장바구니'),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: const BackButton(color: Colors.black),
      ),
      body: _cartItems.isEmpty
          ? const Center(
              child: Text('장바구니가 비어있습니다.', style: TextStyle(fontSize: 16, color: Colors.grey)),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: _cartItems.length,
                    itemBuilder: (context, index) {
                      final item = _cartItems[index];
                      return _buildCartItemCard(item, formatter);
                    },
                  ),
                ),
                _buildTotalSection(formatter),
              ],
            ),
    );
  }

  Widget _buildCartItemCard(CartItem item, NumberFormat formatter) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[200],
                  child: const Icon(Icons.photo_size_select_actual_outlined, color: Colors.grey, size: 40),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.productName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('${formatter.format(item.price)}원', style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildQuantityButton(Icons.remove, () => _decrementQuantity(item)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(item.quantity.toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      _buildQuantityButton(Icons.add, () => _incrementQuantity(item)),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.grey),
              onPressed: () => _removeItem(item),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityButton(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }

  Widget _buildTotalSection(NumberFormat formatter) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('총 상품 금액', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('${formatter.format(_calculateTotal())}원', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent)),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // TODO: 실제 결제 로직 연동
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('결제 기능은 아직 구현되지 않았습니다.')),
              );
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('주문하기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
