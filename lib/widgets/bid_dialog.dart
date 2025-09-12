import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart';

class BidDialog extends StatefulWidget {
  final Product product;
  final bool isBuy; // true: 구매, false: 판매

  const BidDialog({super.key, required this.product, required this.isBuy});

  @override
  State<BidDialog> createState() => _BidDialogState();
}

class _BidDialogState extends State<BidDialog> {
  final TextEditingController _priceController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isBuy ? '구매 입찰' : '판매 입찰';
    final collectionName = widget.isBuy ? 'bids' : 'asks';

    return AlertDialog(
      title: Text(title),
      content: TextField(
        controller: _priceController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(labelText: '희망가 (원)'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('취소')),
        ElevatedButton(
          onPressed: _loading
              ? null
              : () async {
                  final price = double.tryParse(_priceController.text);
                  final user = FirebaseAuth.instance.currentUser;

                  if (user == null) return;

                  if (price == null || price <= 0) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('유효한 가격을 입력해주세요.')));
                    return;
                  }

                  setState(() => _loading = true);

                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);

                  await FirebaseFirestore.instance.collection(collectionName).add({
                    'productId': widget.product.id,
                    'userId': user.uid,
                    'price': price,
                    'createdAt': FieldValue.serverTimestamp(),
                    'status': 'active',
                  });

                  if (!mounted) return;
                  setState(() => _loading = false);
                  navigator.pop();
                  messenger.showSnackBar(
                      const SnackBar(content: Text('입찰이 등록되었습니다.')));
                },
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('입찰 등록'),
        ),
      ],
    );
  }
}