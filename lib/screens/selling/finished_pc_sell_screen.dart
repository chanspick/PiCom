// lib/screens/selling/finished_pc_sell_screen.dart
import 'package:flutter/material.dart';
import 'package:picom/models/base_part_model.dart'; // BasePart 모델 import
import 'package:picom/models/part_model.dart' show PartCategory; // PartCategory Enum만 사용
import 'package:picom/screens/product/search_screen.dart';
import 'package:picom/widgets/pc_part_list_view.dart';
import 'sell_request_details_screen.dart';

class FinishedPcSellScreen extends StatefulWidget {
  const FinishedPcSellScreen({super.key});

  @override
  State<FinishedPcSellScreen> createState() => _FinishedPcSellScreenState();
}

class _FinishedPcSellScreenState extends State<FinishedPcSellScreen> {
  // === 수정: Part?에서 BasePart?로 상태 타입 변경 ===
  final Map<PartCategory, BasePart?> _selectedComponents = {
    PartCategory.cpu: null, PartCategory.mainboard: null, PartCategory.ram: null,
    PartCategory.gpu: null, PartCategory.ssd: null, PartCategory.psu: null,
    PartCategory.cooler: null, PartCategory.pccase: null,
  };

  /// SearchScreen을 호출하여 특정 카테고리의 BasePart를 선택하게 하는 함수
  Future<void> _selectBasePartForCategory(PartCategory category) async {
    // SearchScreen이 BasePart 객체를 반환하도록 수정되었다고 가정합니다.
    final selectedBasePart = await Navigator.push<BasePart?>(
      context,
      MaterialPageRoute(
        builder: (context) => SearchScreen(category: category.name),
      ),
    );

    if (selectedBasePart != null) {
      setState(() {
        _selectedComponents[category] = selectedBasePart;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // === 수정: BasePart 타입으로 리스트 추출 ===
    final selectedBaseParts = _selectedComponents.values.whereType<BasePart>().toList();

    return Scaffold(
      appBar: AppBar(title: const Text('판매할 PC 구성')),
      body: Column(
        children: [
          Expanded(
            child: PcPartListView(
              selectedComponents: _selectedComponents,
              onSelectComponent: _selectBasePartForCategory,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              onPressed: selectedBaseParts.isEmpty
                  ? null
                  : () {
                // === 수정: 상세 정보 입력 화면으로 BasePart 리스트 전달 ===
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SellRequestDetailsScreen(
                      selectedBaseParts: selectedBaseParts,
                    ),
                  ),
                );
              },
              child: const Text('다음 (상세 정보 입력)'),
            ),
          ),
        ],
      ),
    );
  }
}