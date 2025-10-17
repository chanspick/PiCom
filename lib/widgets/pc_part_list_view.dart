import 'package:flutter/material.dart';
import 'package:picom/models/base_part_model.dart'; // ✅ BasePart import 추가
import 'package:picom/models/listing_model.dart';
import 'package:picom/models/part_model.dart';

/// 부품 슬롯 목록을 표시하는 재사용 가능한 'Dumb' 위젯
class PcPartListView extends StatelessWidget {
  /// 화면에 표시할 부품 카테고리별 선택된 컴포넌트 맵
  /// [Part], [Listing], [BasePart] 타입의 객체를 가질 수 있습니다.
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
    final categories = selectedComponents.keys.toList();

    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final selectedComponent = selectedComponents[category];

        // ✅ 선택 여부 확인
        final isSelected = selectedComponent != null;

        // ✅ 화면에 표시될 모델명과 서브타이틀 결정
        String modelName = '선택되지 않음';
        String subtitle = '버튼을 눌러 부품을 선택하세요.';

        // ✅ BasePart 타입 체크 추가!
        if (selectedComponent is BasePart) {
          modelName = selectedComponent.modelName;
          subtitle = '${selectedComponent.category} 선택됨';
        } else if (selectedComponent is Part) {
          modelName = selectedComponent.modelName;
          subtitle = selectedComponent.brand;
        } else if (selectedComponent is Listing) {
          modelName = selectedComponent.modelName;
          subtitle = selectedComponent.brand;
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          elevation: isSelected ? 2 : 0.5,
          color: isSelected ? Colors.blue.shade50 : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? Colors.blue.shade300 : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey.shade400,
              child: Text(
                _categoryToInitial(category),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              _categoryToString(category),
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  modelName,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    color: isSelected ? Colors.black87 : Theme.of(context).hintColor,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
                if (isSelected)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
            trailing: ElevatedButton.icon(
              onPressed: () => onSelectComponent(category),
              icon: Icon(isSelected ? Icons.edit : Icons.add, size: 18),
              label: Text(isSelected ? '변경' : '선택'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade300,
                foregroundColor: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ),
        );
      },
    );
  }

  // --- Helper Methods ---

  String _categoryToString(PartCategory category) {
    switch (category) {
      case PartCategory.cpu:
        return 'CPU';
      case PartCategory.mainboard:
        return '메인보드';
      case PartCategory.ram:
        return 'RAM';
      case PartCategory.gpu:
        return '그래픽카드';
      case PartCategory.ssd:
        return 'SSD';
      case PartCategory.psu:
        return '파워 서플라이';
      case PartCategory.cooler:
        return 'CPU 쿨러';
      case PartCategory.pccase:
        return '케이스';
    }
  }

  String _categoryToInitial(PartCategory category) {
    switch (category) {
      case PartCategory.cpu:
        return 'C';
      case PartCategory.mainboard:
        return 'M';
      case PartCategory.ram:
        return 'R';
      case PartCategory.gpu:
        return 'G';
      case PartCategory.ssd:
        return 'S';
      case PartCategory.psu:
        return 'P';
      case PartCategory.cooler:
        return 'C';
      case PartCategory.pccase:
        return 'C';
    }
  }
}
