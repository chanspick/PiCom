
import 'package:flutter/material.dart';
import '../community/community_screen.dart';

class GuidelineScreen extends StatelessWidget {
  const GuidelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('거래 가이드라인'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('중고 컴퓨터 거래 공식 가이드라인'),
            const Text('본 문서는 중고 컴퓨터 거래 플랫폼에서 구매자 및 판매자가 따라야 할 전체 거래 프로세스입니다.'),
            const Divider(height: 30, thickness: 1),
            _buildSection(
              'Ⅰ. 구매자 절차',
              '1. 구매 요청 및 결제\n' 
              '• 원하는 부품 또는 완제품을 플랫폼에서 선택(장바구니) 및 구매 요청\n' 
              '• 결제 수단(현재 카카오페이만 지원)으로 선결제 진행\n\n' 
              '2. 스트레스 테스트 결과 확인\n' 
              '• 담당자가 공식 매뉴얼에 따라 부품별 스트레스 테스트를 실시\n' 
              '• 테스트 결과(수치, 사진, 환경, 오류 여부)를 구매자에게 전달\n' 
              '• 구매자는 결과 내용을 확인\n\n' 
              '3. 거래 확정 및 수령 방법 선택\n' 
              '• 테스트 결과에 이상이 없으면 플랫폼에서 구매 확정\n' 
              '• 테스트 결과에 이상이 있으면 전액 환불 진행\n' 
              '• 다음 중 한 가지 방식으로 수령 방법 선택\n' 
              'o 택배 배송: 배송지 정보 입력 후 상품 발송 // 배송비 5000원\n' 
              'o 오피스 방문: 지정된 사무실에서 실물 확인 및 직접 수령',
            ),
            _buildSection(
              'Ⅱ. 판매자 절차',
              '1. 판매 요청 및 예상가격 확인\n' 
              '• 판매 요청을 플랫폼에 제출\n' 
              '• 예상가격 산출 알고리즘에 따라 금액이 제안됨\n' 
              '• 제안가를 참고하여 희망가격으로 매물 등록\n\n' 
              '2. 구매 체결 및 알림\n' 
              '• 구매자가 결제 및 거래 확정 시 즉시 알림 수신\n' 
              '• 알림엔 수령 방식(택배/오피스 방문)에 대한 안내 포함\n\n' 
              '3. 제품 전달 및 테스트 진행\n' 
              '• 오피스 방문: 지정 사무실로 직접 제품 제출\n' 
              '• 택배 거래: 상품을 안전하게 포장하여 지정 주소로 발송 // 배송비 본인부담\n' 
              '• 담당자가 공식 매뉴얼에 따라 부품별 스트레스 테스트를 실시\n' 
              '• 스트레스 테스트 결과 이상이 발견될 경우, 제품은 판매자 자택으로 반송\n\n' 
              '4. 정산\n' 
              '• 거래 확정 및 결제 완료\n' 
              '• 판매 금액에서 3% 서비스 수수료 공제\n' 
              '• 잔액을 판매자 계좌로 입금',
            ),
            _buildSection(
              'Ⅲ. 공통 주의사항 및 정책',
              '• 모든 거래 내역 및 테스트 결과는 기록·보존되어 분쟁 시 증빙 자료로 활용\n' 
              '• 테스트 누락 또는 허위 정보 제공, 공식 절차 미준수 시 거래 취소 가능\n' 
              '• 결제, 검수, 배송, 정산 모든 과정은 플랫폼이 신뢰성 있게 자동화·운영\n' 
              '• 본 가이드라인은 운영상 필요에 따라 정기적으로 개정·최신화될 수 있음',
            ),
            const Divider(height: 30, thickness: 1),
            const Text('이 공식 가이드라인은 안전하고 투명한 중고 컴퓨터 거래 문화 정착을 위해 마련되었습니다.'),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
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
