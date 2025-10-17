// lib/screens/selling/finished_pc_sell_screen.dart

import 'package:flutter/material.dart';
import '../../models/base_part_model.dart';
import '../../models/part_model.dart' show PartCategory;
import '../product/search_screen.dart';
import '../../widgets/pc_part_list_view.dart';
import 'sell_request_details_screen.dart';

class FinishedPcSellScreen extends StatefulWidget {
  const FinishedPcSellScreen({super.key});

  @override
  State<FinishedPcSellScreen> createState() => _FinishedPcSellScreenState();
}

class _FinishedPcSellScreenState extends State<FinishedPcSellScreen> {
  final Map<PartCategory, BasePart?> _selectedComponents = {
    PartCategory.cpu: null,
    PartCategory.mainboard: null,
    PartCategory.ram: null,
    PartCategory.gpu: null,
    PartCategory.ssd: null,
    PartCategory.psu: null,
    PartCategory.cooler: null,
    PartCategory.pccase: null,
  };

  Future<void> _selectBasePartForCategory(PartCategory category) async {
    final selectedBasePart = await Navigator.push<BasePart>(
      context,
      MaterialPageRoute(
        builder: (context) => SearchScreen(category: category.name),
      ),
    );

    if (selectedBasePart != null) {
      setState(() {
        _selectedComponents[category] = selectedBasePart;
        print('✅ 선택됨: ${category.name} - ${selectedBasePart.modelName}');
      });
    }
  }

  void _goToDetailsScreen() {
    final selectedBaseParts = _selectedComponents.values
        .whereType<BasePart>()
        .toList();

    if (selectedBaseParts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('최소 1개 이상의 부품을 선택해주세요.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SellRequestDetailsScreen(
          selectedBaseParts: selectedBaseParts,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _selectedComponents.values
        .where((part) => part != null)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('판매할 PC 구성'),
        actions: [
          if (selectedCount > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Text(
                  '$selectedCount개 선택됨',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // 안내 메시지
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '판매할 PC의 부품을 선택해주세요.\n최소 1개 이상 선택하면 다음 단계로 진행할 수 있습니다.',
                    style: TextStyle(
                      color: Colors.blue.shade900,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ✅ PcPartListView 사용 (파라미터 이름 수정)
          Expanded(
            child: PcPartListView(
              key: ValueKey(_selectedComponents.hashCode),
              selectedComponents: Map<PartCategory, dynamic>.from(_selectedComponents),
              onSelectComponent: _selectBasePartForCategory, // ✅ 올바른 파라미터명
            ),
          ),

          // 다음 버튼
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: selectedCount > 0
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade300,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: selectedCount > 0 ? _goToDetailsScreen : null,
                child: Text(
                  selectedCount > 0
                      ? '다음 단계 (상세 정보 입력)'
                      : '부품을 선택해주세요',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
