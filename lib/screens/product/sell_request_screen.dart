// lib/screens/product/sell_request_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
// === BasePart로 변경 ===
import '../../models/base_part_model.dart';
import '../../models/sell_request_model.dart';
import 'part_search_screen.dart'; // PartSearchScreen으로 변경
import '../../services/sell_request_service.dart';
import '../../services/auth_service.dart';

class SellRequestScreen extends StatefulWidget {
  const SellRequestScreen({super.key});

  @override
  State<SellRequestScreen> createState() => _SellRequestScreenState();
}

class _SellRequestScreenState extends State<SellRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sellRequestService = SellRequestService();
  final _authService = AuthService();

  // === BasePart로 변경 ===
  BasePart? _selectedPart;
  bool _hasWarranty = false;
  int? _usageDaysPerWeek;
  int? _usageHoursPerDay;
  String? _selectedPurpose;
  List<File> _images = [];
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _isUnused = false;

  final _warrantyMonthsController = TextEditingController();
  final _otherPurposeController = TextEditingController();
  final _requestedPriceController = TextEditingController();

  AgeInfoType _selectedAgeInfoType = AgeInfoType.unknown;
  bool _isSecondHand = false;
  final _yearController = TextEditingController();
  final _monthController = TextEditingController();

  final List<String> _purposes = ['일상용', '게임용', '개발용', '사무용', '기타'];

  @override
  void dispose() {
    _warrantyMonthsController.dispose();
    _otherPurposeController.dispose();
    _requestedPriceController.dispose();
    _yearController.dispose();
    _monthController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile>? pickedFiles = await _picker.pickMultiImage(
      imageQuality: 70,
      maxWidth: 1000,
    );
    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      setState(() {
        _images = pickedFiles.map((file) => File(file.path)).toList();
      });
    }
  }

  Future<void> _navigateToSearchScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PartSearchScreen(), // 변경
      ),
    );
    // === BasePart 타입으로 받기 ===
    if (result != null && result is BasePart) {
      setState(() {
        _selectedPart = result;
      });
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('입력되지 않은 필수 항목이 있습니다.'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사진을 1장 이상 추가해주세요.'), backgroundColor: Colors.red),
      );
      return;
    }

    if (!_authService.requireAuth(context)) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      String purpose = _selectedPurpose!;
      if (purpose == '기타') {
        purpose = _otherPurposeController.text;
      }

      final int? year = _selectedAgeInfoType != AgeInfoType.unknown
          ? int.tryParse(_yearController.text)
          : null;
      final int? month = _selectedAgeInfoType != AgeInfoType.unknown
          ? int.tryParse(_monthController.text)
          : null;

      final String usageFrequency = _isUnused
          ? '미사용'
          : '주 $_usageDaysPerWeek일, 하루 $_usageHoursPerDay시간';

      // === File을 XFile로 변환 ===
      final List<XFile> xFileImages = _images.map((file) => XFile(file.path)).toList();

      // === XFile 리스트로 전달 ===
      await _sellRequestService.createSellRequestFromBasePart(
        basePart: _selectedPart!,
        ageInfoType: _selectedAgeInfoType,
        ageInfoYear: year,
        ageInfoMonth: month,
        isSecondHand: _isSecondHand,
        hasWarranty: _hasWarranty,
        warrantyMonthsLeft: _hasWarranty ? int.tryParse(_warrantyMonthsController.text) : null,
        usageFrequency: usageFrequency,
        purpose: purpose,
        requestedPrice: int.parse(_requestedPriceController.text),
        images: xFileImages, // XFile 리스트로 전달
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('판매 요청이 성공적으로 제출되었습니다.')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('제품 사진 (최대 5장)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImages,
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey),
            ),
            child: _images.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt, color: Colors.grey[600]),
                  Text('사진 추가', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            )
                : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _images.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.file(_images[index], width: 90, height: 90, fit: BoxFit.cover),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAgeInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text('부품 연식 정보 📝', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text('부품의 연식을 정확히 입력하면 더 높은 컨디션 스코어를 받을 수 있습니다.', style: Theme.of(context).textTheme.bodySmall),
        RadioListTile<AgeInfoType>(
          title: const Text('최초 신품 구매일'),
          value: AgeInfoType.originalPurchaseDate,
          groupValue: _selectedAgeInfoType,
          onChanged: (value) => setState(() => _selectedAgeInfoType = value!),
        ),
        RadioListTile<AgeInfoType>(
          title: const Text('제조년월'),
          value: AgeInfoType.manufactureDate,
          groupValue: _selectedAgeInfoType,
          onChanged: (value) => setState(() => _selectedAgeInfoType = value!),
        ),
        RadioListTile<AgeInfoType>(
          title: const Text('정보 없음'),
          value: AgeInfoType.unknown,
          groupValue: _selectedAgeInfoType,
          onChanged: (value) => setState(() => _selectedAgeInfoType = value!),
        ),
        if (_selectedAgeInfoType == AgeInfoType.unknown)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '연식 정보를 알 수 없어 컨디션 스코어가 일부 하락할 수 있습니다.',
                    style: TextStyle(color: Colors.deepOrange),
                  ),
                ),
              ],
            ),
          ),
        if (_selectedAgeInfoType != AgeInfoType.unknown)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _yearController,
                    decoration: const InputDecoration(labelText: '년도 (YYYY)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                    validator: (value) {
                      if (_selectedAgeInfoType != AgeInfoType.unknown && (value == null || value.isEmpty || value.length < 4)) {
                        return '4자리 년도';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _monthController,
                    decoration: const InputDecoration(labelText: '월 (MM)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
                    validator: (value) {
                      if (_selectedAgeInfoType != AgeInfoType.unknown && (value == null || value.isEmpty)) {
                        return '월 입력';
                      }
                      if (_selectedAgeInfoType != AgeInfoType.unknown) {
                        final month = int.tryParse(value!);
                        if (month == null || month < 1 || month > 12) {
                          return '1-12';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildOwnershipSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text('소유 이력 🤝', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        RadioListTile<bool>(
          title: const Text('제가 신품으로 직접 구매했어요.'),
          value: false,
          groupValue: _isSecondHand,
          onChanged: (value) => setState(() => _isSecondHand = value!),
        ),
        RadioListTile<bool>(
          title: const Text('저도 중고로 구매했어요.'),
          value: true,
          groupValue: _isSecondHand,
          onChanged: (value) => setState(() => _isSecondHand = value!),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('판매 요청')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            FormField<BasePart>(
              builder: (FormFieldState<BasePart> state) {
                return InkWell(
                  onTap: _navigateToSearchScreen,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: '제품 모델',
                      border: const OutlineInputBorder(),
                      errorText: state.errorText,
                    ),
                    child: _selectedPart == null
                        ? Text('탭하여 부품 검색', style: TextStyle(color: Theme.of(context).hintColor))
                        : Text('${_selectedPart!.category} - ${_selectedPart!.modelName}'),
                  ),
                );
              },
              validator: (value) {
                if (_selectedPart == null) return '제품 모델을 선택해주세요.';
                return null;
              },
            ),
            _buildAgeInfoSection(),
            _buildOwnershipSection(),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('AS 기간 남음'),
              value: _hasWarranty,
              onChanged: (bool value) => setState(() => _hasWarranty = value),
              secondary: const Icon(Icons.shield_outlined),
            ),
            if (_hasWarranty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 16.0, right: 16.0),
                child: TextFormField(
                  controller: _warrantyMonthsController,
                  decoration: const InputDecoration(labelText: '남은 AS 개월 수', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (_hasWarranty && (value == null || value.isEmpty)) return '개월 수를 입력해주세요.';
                    return null;
                  },
                ),
              ),
            const SizedBox(height: 16),
            const Text('사용 빈도', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            CheckboxListTile(
              title: const Text("미사용 (개봉 후 보관만 했어요)"),
              value: _isUnused,
              onChanged: (bool? value) {
                setState(() {
                  _isUnused = value!;
                  if (_isUnused) {
                    _usageDaysPerWeek = null;
                    _usageHoursPerDay = null;
                  }
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            IgnorePointer(
              ignoring: _isUnused,
              child: Opacity(
                opacity: _isUnused ? 0.5 : 1.0,
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        decoration: const InputDecoration(labelText: '주', border: OutlineInputBorder()),
                        value: _usageDaysPerWeek,
                        items: List.generate(7, (i) => i + 1).map((d) => DropdownMenuItem(value: d, child: Text('$d일'))).toList(),
                        onChanged: (value) => setState(() => _usageDaysPerWeek = value),
                        validator: (v) {
                          if (!_isUnused && v == null) return '선택';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        decoration: const InputDecoration(labelText: '하루', border: OutlineInputBorder()),
                        value: _usageHoursPerDay,
                        items: List.generate(24, (i) => i + 1).map((h) => DropdownMenuItem(value: h, child: Text('$h시간'))).toList(),
                        onChanged: (value) => setState(() => _usageHoursPerDay = value),
                        validator: (v) {
                          if (!_isUnused && v == null) return '선택';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('주 사용 용도', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              children: _purposes.map((purpose) => ChoiceChip(
                label: Text(purpose),
                selected: _selectedPurpose == purpose,
                onSelected: (selected) => setState(() => _selectedPurpose = selected ? purpose : null),
              )).toList(),
            ),
            if (_selectedPurpose == null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text('용도를 선택해주세요.', style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
              ),
            if (_selectedPurpose == '기타')
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: TextFormField(
                  controller: _otherPurposeController,
                  decoration: const InputDecoration(labelText: '기타 용도 입력', border: OutlineInputBorder()),
                  validator: (value) {
                    if (_selectedPurpose == '기타' && (value == null || value.isEmpty)) return '기타 용도를 입력해주세요.';
                    return null;
                  },
                ),
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _requestedPriceController,
              decoration: const InputDecoration(labelText: '희망 판매 가격', border: OutlineInputBorder(), suffixText: '원'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) return '가격을 입력해주세요.';
                if (int.tryParse(value) == null || int.parse(value) <= 0) return '유효한 가격을 입력해주세요.';
                return null;
              },
            ),
            const SizedBox(height: 24),
            _buildImagePicker(),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitRequest,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('판매 요청 제출'),
            ),
          ],
        ),
      ),
    );
  }
}
