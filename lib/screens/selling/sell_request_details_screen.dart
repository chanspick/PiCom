// lib/screens/selling/sell_request_details_screen.dart
import 'package:flutter/foundation.dart' show kIsWeb; // 웹 플랫폼 확인용
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart'; // XFile 사용
import 'dart:io'; // 모바일에서 File을 사용하기 위해 import

import 'package:picom/models/base_part_model.dart';
import 'package:picom/models/sell_request_model.dart';
import 'package:picom/services/auth_service.dart';
import 'package:picom/services/sell_request_service.dart';

class SellRequestDetailsScreen extends StatefulWidget {
  final List<BasePart> selectedBaseParts;
  const SellRequestDetailsScreen({super.key, required this.selectedBaseParts});

  @override
  State<SellRequestDetailsScreen> createState() => _SellRequestDetailsScreenState();
}

class _SellRequestDetailsScreenState extends State<SellRequestDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sellRequestService = SellRequestService();
  final _authService = AuthService();

  // === 수정: List<File> -> List<XFile> ===
  List<XFile> _images = [];
  final ImagePicker _picker = ImagePicker();

  // (이하 다른 상태 변수 및 컨트롤러들은 동일)
  bool _isLoading = false;
  late Map<String, TextEditingController> _brandControllers;
  // ...

  @override
  void initState() {
    super.initState();
    _brandControllers = {
      for (var part in widget.selectedBaseParts)
        part.basePartId: TextEditingController()
    };
  }
  Future<void> _pickImages() async {
    final List<XFile>? pickedFiles = await _picker.pickMultiImage(
      imageQuality: 70, maxWidth: 1000,
    );
    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      setState(() {
        _images = pickedFiles; // File로 변환하지 않고 그대로 할당
      });
    }
  }

  @override
  void dispose() {
    // 모든 컨트롤러를 dispose하여 메모리 누수를 방지합니다.
    _yearController.dispose();
    _monthController.dispose();
    _totalPriceController.dispose();
    for (var controller in _brandControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // --- Main Logic ---
  Future<void> _submitRequests() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('입력되지 않은 필수 항목이 있습니다.')),
      );
      return;
    }
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사진을 1장 이상 추가해주세요.')),
      );
      return;
    }
    if (!_authService.requireAuth(context)) return;

    setState(() => _isLoading = true);

    try {
      // 각 부품의 브랜드 정보를 Map<String, String> 형태로 변환
      final brands = _brandControllers.map(
            (partId, controller) => MapEntry(partId, controller.text),
      );

      // SellRequestService의 일괄 생성 메서드 호출
      await _sellRequestService.createMultipleSellRequestsFromBaseParts(
        baseParts: widget.selectedBaseParts,
        brands: brands,
        // --- 폼에서 입력받은 공통 정보 전달 ---
        ageInfoType: _selectedAgeInfoType,
        ageInfoYear: int.tryParse(_yearController.text),
        ageInfoMonth: int.tryParse(_monthController.text),
        isSecondHand: _isSecondHand,
        isUnused: _isUnused,
        totalPrice: int.parse(_totalPriceController.text),
        images: _images,
        // ... (AS기간, 사용빈도 등 추가 정보가 있다면 여기에 전달) ...
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('판매 요청이 성공적으로 제출되었습니다.')),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류가 발생했습니다: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- UI Builder Methods ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('판매 정보 입력')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          children: [
            _buildSelectedPartsSection(),
            const Divider(height: 40),
            _buildBrandInputSection(),
            const Divider(height: 40),
            // --- 이하 UI는 sell_request_screen.dart에서 가져와 재활용 ---
            // 여기에 AgeInfo, Ownership, Usage, Price, ImagePicker 관련 위젯들을 배치합니다.
            // 예시: _buildAgeInfoSection(), _buildOwnershipSection() ...
            _buildPriceSection(),
            const SizedBox(height: 24),
            _buildImagePicker(),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              onPressed: _isLoading ? null : _submitRequests,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('판매 요청 일괄 제출'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedPartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '판매 대상 부품 (${widget.selectedBaseParts.length}개)',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: widget.selectedBaseParts
                  .map((part) => Text(
                '• ${part.modelName} (${part.category})',
                style: const TextStyle(fontSize: 16),
              ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBrandInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('브랜드 (제조사) 입력', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text('각 부품의 브랜드를 정확히 입력해주세요.', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 16),
        ...widget.selectedBaseParts.map((part) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: TextFormField(
              controller: _brandControllers[part.basePartId],
              decoration: InputDecoration(
                labelText: part.modelName,
                hintText: '예: ASUS, 삼성전자, GIGABYTE',
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '${part.modelName}의 브랜드를 입력해주세요.';
                }
                return null;
              },
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('희망 판매 가격', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        TextFormField(
          controller: _totalPriceController,
          decoration: const InputDecoration(
            labelText: '총 희망 판매 가격',
            border: OutlineInputBorder(),
            suffixText: '원',
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value == null || value.isEmpty) return '가격을 입력해주세요.';
            return null;
          },
        ),
      ],
    );
  }

  // _buildImagePicker, _buildAgeInfoSection 등 sell_request_screen.dart의
  // 위젯 빌더 메서드들을 여기에 그대로 복사하여 재활용할 수 있습니다.
  Widget _buildImagePicker() {
    // sell_request_screen.dart에서 동일한 메서드를 복사
    return Container(); // Placeholder
  }
}