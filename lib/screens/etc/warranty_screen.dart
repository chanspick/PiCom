
import 'package:flutter/material.dart';
import '../community/community_screen.dart';

class WarrantyScreen extends StatelessWidget {
  const WarrantyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('보증 안내'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('중고 컴퓨터 거래 플랫폼 보증 내규'),
            const Divider(height: 30, thickness: 1),
            _buildSection('1. 목적', '본 내규는 중고 컴퓨터 거래 플랫폼에서 모든 구매자에게 투명하고 합리적인 사후 보증 서비스를 제공함으로써, 거래의 신뢰성과 고객 만족을 높이는 데 목적이 있습니다.'),
            _buildSection(
              '2. 보증 기간 및 수수료 정책',
              '• 모든 구매자는 구매 즉시 기본 3개월 무상 보증을 제공합니다.\n'
              '• 구매자는 선택적으로 추가 수수료(구매한 제품 금액의 일정 비율)를 납부하여 장기 보증을 선택할 수 있습니다.\n'
              '• 구매 제품 금액의 3% 추가 납부 시: 6개월 무상 보증 제공\n'
              '• 구매 제품 금액의 6% 추가 납부 시: 12개월 무상 보증 제공\n'
              '• 구매 제품 금액의 9% 추가 납부 시: 24개월 무상 보증 제공',
            ),
            _buildSection(
              '3. 보증 서비스 제공 방식',
              '• 무상 수리:\n'
              '보증 기간 내 제품에 하자가 발생할 경우, 무상으로 수리 서비스를 제공합니다.\n'
              '• 수리 불가 시 교환:\n'
              '동일 부품 또는 제품의 수리가 어려울 경우, 동급 또는 한 단계 상위 사양의 제품으로 무상 교환 처리합니다.',
            ),
            _buildSection(
              '4. 보증 적용 및 제외 기준',
              '• 본 보증은 공식 스트레스 테스트를 통과하고 거래 내역이 플랫폼에 기록된 제품에 한하여 적용됩니다.\n'
              '• 다음과 같은 경우에는 보증이 제한될 수 있습니다.\n'
              '• 사용자 부주의(외부 충격, 침수, 임의 분해·개조 등)에 의한 고장\n'
              '• 상기한 사용자 부주의에 의한 고장은 스티커 훼손여부로 판단됩니다.\n'
              '• 제품 정보 및 거래 기록이 누락된 경우\n'
              '• OS/소프트웨어 문제 및 바이러스 감염 등 하드웨어 외 원인',
            ),
            _buildSection(
              '5. AS 처리 절차',
              '1. 구매자가 플랫폼 내 AS 신청\n'
              '2. 담당자가 제품 회수 및 이상 유무 확인\n'
              '3. 수리가 가능한 경우 무상 수리 진행\n'
              '4. 수리가 불가능할 경우 동급 또는 상위 제품으로 무상 교환\n'
              '5. 모든 처리 내역을 공식 기록 및 구매자에게 결과 통보',
            ),
            _buildSection(
              '6. 기타',
              '• 모든 보증·처리 내역은 플랫폼에 기록·보관되어 분쟁 시 근거 자료로 활용됩니다.\n'
              '• 본 내규는 서비스 운영 상황, 시장 동향에 따라 개정될 수 있으며, 개정 시 사전 공지합니다.',
            ),
            const SizedBox(height: 32),
            const Text(
              '더 궁금한게 있다면? 망설이지말고 질문하세요.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CommunityScreen()),
                  );
                },
                child: const Text('Q&A 게시판으로 이동'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(fontSize: 16, height: 1.5),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
