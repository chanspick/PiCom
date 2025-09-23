
import 'package:flutter/material.dart';
import 'package:picom/models/product_model.dart'; // Product 모델 import
import 'package:intl/intl.dart'; // NumberFormat을 위해 추가
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentScreen extends StatefulWidget {
  final Product product; // Product 객체를 받도록 수정

  const PaymentScreen({super.key, required this.product});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

enum PaymentMethod { creditCard, naverPay, kakaoPay, tossPay, bankTransfer }

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentMethod? _selectedPaymentMethod = PaymentMethod.creditCard;
  bool _isAgreed = false;
  final Dio _dio = Dio();

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###'); // formatter 추가

    return Scaffold(
      appBar: AppBar(
        title: const Text('결제하기'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderInfo(),
            _buildDivider(),
            _buildPaymentMethod(),
            _buildDivider(),
            _buildPaymentSummary(formatter), // formatter 전달
            _buildDivider(),
            _buildAgreement(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomPayButton(formatter), // formatter 전달
    );
  }

  Widget _buildOrderInfo() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '주문 상품',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                  image: DecorationImage(
                    image: NetworkImage(widget.product.imageUrl), // 실제 상품 이미지 사용
                    fit: BoxFit.cover,
                  ),
                ),
                child: widget.product.imageUrl.isEmpty
                    ? const Icon(Icons.broken_image, size: 40, color: Colors.grey) // 이미지가 없을 경우 아이콘 표시
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name, // 실제 상품명 사용
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text('수량: 1개'), // 수량은 임시로 1개로 고정
                    const SizedBox(height: 8),
                    Text(
                      '${NumberFormat('#,###').format(widget.product.lastTradedPrice)}원', // 실제 상품 가격 사용
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '결제 방법',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildPaymentOption(
            title: '신용/체크카드',
            value: PaymentMethod.creditCard,
          ),
          _buildPaymentOption(
            title: '네이버페이',
            value: PaymentMethod.naverPay,
          ),
          _buildPaymentOption(
            title: '카카오페이',
            value: PaymentMethod.kakaoPay,
          ),
          _buildPaymentOption(
            title: '토스페이',
            value: PaymentMethod.tossPay,
          ),
          _buildPaymentOption(
            title: '계좌이체',
            value: PaymentMethod.bankTransfer,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({required String title, required PaymentMethod value}) {
    return RadioListTile<PaymentMethod>(
      title: Text(title),
      value: value,
      groupValue: _selectedPaymentMethod,
      onChanged: (PaymentMethod? value) {
        setState(() {
          _selectedPaymentMethod = value;
        });
      },
      activeColor: Colors.black,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildPaymentSummary(NumberFormat formatter) {
    final productPrice = widget.product.lastTradedPrice;
    const deliveryFee = 3000; // 임시 배송비
    final totalAmount = productPrice + deliveryFee;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '최종 결제금액',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('상품금액', '${formatter.format(productPrice)}원'),
          const SizedBox(height: 8),
          _buildSummaryRow('배송비', '${formatter.format(deliveryFee)}원'),
          const Divider(height: 24),
          _buildSummaryRow('총 결제금액', '${formatter.format(totalAmount)}원', isTotal: true),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String title, String amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: isTotal ? 20 : 16,
            fontWeight: FontWeight.bold,
            color: isTotal ? Colors.red : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildAgreement() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Checkbox(
            value: _isAgreed,
            onChanged: (bool? value) {
              setState(() {
                _isAgreed = value ?? false;
              });
            },
            activeColor: Colors.black,
          ),
          const Expanded(
            child: Text(
              '주문 내용을 확인했으며, 결제에 동의합니다.',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPayButton(NumberFormat formatter) {
    final productPrice = widget.product.lastTradedPrice;
    const deliveryFee = 3000; // 임시 배송비
    final totalAmount = productPrice + deliveryFee;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), // Bottom padding for safe area
      color: Colors.white,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _isAgreed ? Colors.black : Colors.grey,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _isAgreed
            ? () async {
                if (_selectedPaymentMethod == PaymentMethod.kakaoPay) {
                  await _requestKakaoPayPayment(totalAmount.round(), widget.product.name);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('선택된 결제 방법은 아직 지원되지 않습니다.')),
                  );
                }
              }
            : null, // 비활성화 상태
        child: Text(
          '${formatter.format(totalAmount)}원 결제하기',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 8,
      color: Colors.grey[100],
    );
  }

  Future<void> _requestKakaoPayPayment(int totalAmount, String itemName) async {
    if (!_isAgreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('결제 동의가 필요합니다.')),
      );
      return;
    }

    try {
      // KakaoPay API 요청을 위한 데이터 구성
      String displayItemName = itemName;
      if (displayItemName.length > 100) { // KakaoPay item_name max length is typically 100
        displayItemName = displayItemName.substring(0, 100);
      }

      final Map<String, dynamic> data = {
        'cid': 'TC0ONETIME', // 테스트용 CID
        'partner_order_id': 'partner_order_id_test', // 가맹점 주문번호
        'partner_user_id': 'partner_user_id_test', // 가맹점 회원 ID
        'item_name': displayItemName, // 상품명
        'quantity': 1, // 상품 수량
        'total_amount': totalAmount, // 총 결제 금액
        'tax_free_amount': 0, // 비과세 금액
        'approval_url': 'https://developers.kakao.com', // 결제 성공 시 리다이렉트 URL
        'cancel_url': 'https://developers.kakao.com/cancel', // 결제 취소 시 리다이렉트 URL
        'fail_url': 'https://developers.kakao.com/fail', // 결제 실패 시 리다이렉트 URL
      };

      final response = await _dio.post(
        'https://kapi.kakao.com/v1/payment/ready',
        options: Options(
          headers: {
            'Authorization': 'KakaoAK 6de8b41e76297e3b2e9b27047ea76408', // 여기에 실제 Admin Key를 입력하세요.
            'Content-Type': 'application/x-www-form-urlencoded;charset=utf-8',
          },
        ),
        data: data,
      );

      if (response.statusCode == 200) {
        final String? nextRedirectPcUrl = response.data['next_redirect_pc_url'];
        if (nextRedirectPcUrl != null) {
          if (await canLaunchUrl(Uri.parse(nextRedirectPcUrl))) {
            await launchUrl(Uri.parse(nextRedirectPcUrl));
          } else {
            throw '카카오페이 결제 페이지를 열 수 없습니다.';
          }
        } else {
          throw '카카오페이 결제 URL을 받지 못했습니다.';
        }
      } else {
        throw '카카오페이 결제 준비 실패: ${response.statusCode} - ${response.data}';
      }
    } on DioException catch (e) {
      String errorMessage = '결제 중 네트워크 오류 발생';
      if (e.response != null) {
        errorMessage = '카카오페이 결제 준비 실패: ${e.response?.statusCode} - ${e.response?.data}';
      } else {
        errorMessage = '결제 중 오류 발생: ${e.message}';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('결제 중 알 수 없는 오류 발생: $e')),
      );
    }
  }
}
