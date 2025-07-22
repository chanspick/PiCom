import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product_model.dart';

class ProductPriceAndActions extends StatelessWidget {
  final Product product;

  const ProductPriceAndActions({
    required this.product,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');

    return Container(
      height: 32, // 고정 높이로 카드 높이 통일에 기여
      alignment: Alignment.centerLeft,
      child: Text(
        '${formatter.format(product.lastTradedPrice)}원',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF42A5F5), // 선명한 파스텔블루 색상
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
