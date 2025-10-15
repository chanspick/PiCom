import 'package:flutter/material.dart';
import 'package:picom/models/listing_model.dart'; // 예시 경로, 실제 프로젝트에 맞게 수정
import 'package:picom/models/part_model.dart';     // 예시 경로, 실제 프로젝트에 맞게 수정

/// 부품 슬롯 목록을 표시하는 재사용 가능한 'Dumb' 위젯
class PcPartListView extends StatelessWidget {
  /// 화면에 표시할 부품 카테고리별 선택된 컴포넌트 맵
  /// [Part] 또는 [Listing] 타입의 객체를 가질 수 있습니다.
  final Map<PartCategory, dynamic> selectedComponents;

  /// 사용자가 특정 카테고리의 '선택' 버튼을 눌렀을 때 호출될 콜백 함수
  final Function(PartCategory) onSelectComponent;

  const PcPartListView({
    super.key,
    required this.selectedComponents,
    required this.onSelectComponent,
  });

  @override
  Widget build(BuildContext context) {
    // selectedComponents 맵의 키(카테고리)들을 리스트로 변환하여 ListView를 구성
    final categories = selectedComponents.keys.toList();

    return ListView.builder(
      // 전체 아이템 개수는 카테고리 리스트의 길이
      itemCount: categories.length,
      itemBuilder: (context, index) {
        // 현재 인덱스에 해당하는 카테고리
        final category = categories[index];
        // 해당 카테고리에 선택된 컴포넌트 객체
        final selectedComponent = selectedComponents[category];

        // 화면에 표시될 모델명을 결정하는 로직
        String modelName = '선택되지 않음';
        String subtitle = '버튼을 눌러 부품을 선택하세요.';

        // 선택된 컴포넌트의 타입에 따라 모델명과 서브타이틀을 다르게 표시
        if (selectedComponent is Part) {
          modelName = selectedComponent.modelName;
          subtitle = selectedComponent.brand;
        } else if (selectedComponent is Listing) {
          modelName = selectedComponent.modelName;
          subtitle = selectedComponent.brand;
        }

        // 각 부품 슬롯을 나타내는 ListTile 위젯
        return ListTile(
          leading: CircleAvatar(
            child: Text(_categoryToInitial(category)),
          ),
          title: Text(_categoryToString(category)),
          subtitle: Text(
            modelName,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(
              // 선택되지 않았을 경우 흐린 색상으로 표시하여 구분감 부여
              color: selectedComponent == null ? Theme.of(context).hintColor : null,
            ),
          ),
          // 오른쪽의 '선택' 버튼
          trailing: ElevatedButton(
            onPressed: () => onSelectComponent(category), // 외부에서 전달받은 함수 호출
            child: const Text('선택'),
          ),
        );
      },
    );
  }

  // --- Helper Methods ---

  /// PartCategory Enum을 화면에 표시될 문자열로 변환
  String _categoryToString(PartCategory category) {
    switch (category) {
      case PartCategory.cpu: return 'CPU';
      case PartCategory.mainboard: return '메인보드';
      case PartCategory.ram: return 'RAM';
      case PartCategory.gpu: return '그래픽카드';
      case PartCategory.ssd: return 'SSD';
      case PartCategory.psu: return '파워 서플라이';
      case PartCategory.cooler: return 'CPU 쿨러';
      case PartCategory.pccase: return '케이스';
    }
  }

  /// PartCategory Enum을 이니셜로 변환 (CircleAvatar용)
  String _categoryToInitial(PartCategory category) {
    switch (category) {
      case PartCategory.cpu: return 'C';
      case PartCategory.mainboard: return 'M';
      case PartCategory.ram: return 'R';
      case PartCategory.gpu: return 'G';
      case PartCategory.ssd: return 'S';
      case PartCategory.psu: return 'P';
      case PartCategory.cooler: return 'C';
      case PartCategory.pccase: return 'C';
    }
  }
}