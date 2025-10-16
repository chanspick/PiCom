// lib/screens/selling/sell_request_details_screen.dart

import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/base_part_model.dart';
import '../../models/sell_request_model.dart';
import '../../services/auth_service.dart';
import '../../services/sell_request_service.dart';

class SellRequestDetailsScreen extends StatefulWidget {
  final List<BasePart> selectedBaseParts;

  const SellRequestDetailsScreen({super.key, required this.selectedBaseParts});

  @override
  State<SellRequestDetailsScreen> createState() =>
      _SellRequestDetailsScreenState();
}

class _SellRequestDetailsScreenState extends State<SellRequestDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sellRequestService = SellRequestService();
  final _authService = AuthService();

  // State
  List<XFile> _images = [];
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  AgeInfoType _selectedAgeInfoType = AgeInfoType.unknown;
  bool _isSecondHand = false;
  bool _hasWarranty = false;
  bool _isUnused = false;
  int? _usageDaysPerWeek;
  int? _usageHoursPerDay;
  String? _selectedPurpose;

  // Controllers
  final _yearController = TextEditingController();
  final _monthController = TextEditingController();
  final _warrantyMonthsController = TextEditingController();
  final _otherPurposeController = TextEditingController();
  late List<TextEditingController> _priceControllers;

  final List<String> _purposes = ['일상용', '게임용', '개발용', '사무용', '기타'];

  @override
  void initState() {
    super.initState();
    // 각 부품별 가격 입력 컨트롤러 생성
    _priceControllers = List.generate(
      widget.selectedBaseParts.length,
          (index) => TextEditingController(),
    );
  }

  @override
  void dispose() {
    _yearController.dispose();
    _monthController.dispose();
    _warrantyMonthsController.dispose();
    _otherPurposeController.dispose();
    for (var controller in _priceControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile>? pickedFiles = await _picker.pickMultiImage(
      imageQuality: 70,
      maxWidth: 1000,
    );
    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      setState(() {
        _images = pickedFiles;
      });
    }
  }

  Future<void> _submitRequests() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('입력되지 않은 필수 항목이 있습니다.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('사진을 1장 이상 추가해주세요.'),
          backgroundColor: Colors.red,
        ),
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

      // TODO: SellRequestService에 아래 메서드 구현 필요
      // createMultipleSellRequestsFromBaseParts() 메서드가 필요합니다.
      // 각 BasePart와 개별 가격을 받아서 여러 개의 SellRequest를 생성해야 합니다.

      // 임시로 각 부품마다 개별 요청 생성
      for (int i = 0; i < widget.selectedBaseParts.length; i++) {
        final basePart = widget.selectedBaseParts[i];
        final requestedPrice = int.parse(_priceControllers[i].text);

        await _sellRequestService.createSellRequestFromBasePart(
          basePart: basePart,
          ageInfoType: _selectedAgeInfoType,
          ageInfoYear: year,
          ageInfoMonth: month,
          isSecondHand: _isSecondHand,
          hasWarranty: _hasWarranty,
          warrantyMonthsLeft: _hasWarranty
              ? int.tryParse(_warrantyMonthsController.text)
              : null,
          usageFrequency: usageFrequency,
          purpose: purpose,
          requestedPrice: requestedPrice,
          images: _images,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('판매 요청이 성공적으로 제출되었습니다.')),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('판매 정보 입력'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildSelectedPartsSection(),
            const SizedBox(height: 24),
            _buildPriceInputSection(),
            const Divider(height: 40),
            _buildAgeInfoSection(),
            const SizedBox(height: 24),
            _buildOwnershipSection(),
            const SizedBox(height: 24),
            _buildWarrantySection(),
            const SizedBox(height: 24),
            _buildUsageSection(),
            const SizedBox(height: 24),
            _buildPurposeSection(),
            const SizedBox(height: 24),
            _buildImagePicker(),
            const SizedBox(height: 32),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedPartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.memory, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(
              '판매할 부품 목록 (${widget.selectedBaseParts.length}개)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: Colors.blue.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.blue.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: widget.selectedBaseParts.map((part) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${part.category} - ${part.modelName}',
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('각 부품별 희망 가격 💰',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          '각 부품의 희망 판매 가격을 개별적으로 입력해주세요.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(widget.selectedBaseParts.length, (index) {
          final part = widget.selectedBaseParts[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: TextFormField(
              controller: _priceControllers[index],
              decoration: InputDecoration(
                labelText: part.modelName,
                hintText: '희망 판매 가격 입력',
                border: const OutlineInputBorder(),
                suffixText: '원',
                prefixIcon: const Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '가격을 입력해주세요.';
                }
                if (int.tryParse(value) == null || int.parse(value) <= 0) {
                  return '유효한 가격을 입력해주세요.';
                }
                return null;
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAgeInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('부품 연식 정보 📝', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          '부품의 연식을 정확히 입력하면 더 높은 컨디션 스코어를 받을 수 있습니다.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 12),
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
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
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
                    decoration: const InputDecoration(
                      labelText: '년도 (YYYY)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    validator: (value) {
                      if (_selectedAgeInfoType != AgeInfoType.unknown &&
                          (value == null || value.isEmpty || value.length < 4)) {
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
                    decoration: const InputDecoration(
                      labelText: '월 (MM)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    validator: (value) {
                      if (_selectedAgeInfoType != AgeInfoType.unknown &&
                          (value == null || value.isEmpty)) {
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

  Widget _buildWarrantySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              decoration: const InputDecoration(
                labelText: '남은 AS 개월 수',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (_hasWarranty && (value == null || value.isEmpty)) {
                  return '개월 수를 입력해주세요.';
                }
                return null;
              },
            ),
          ),
      ],
    );
  }

  Widget _buildUsageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('사용 빈도 ⏱️', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
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
        const SizedBox(height: 8),
        IgnorePointer(
          ignoring: _isUnused,
          child: Opacity(
            opacity: _isUnused ? 0.5 : 1.0,
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: '주',
                      border: OutlineInputBorder(),
                    ),
                    value: _usageDaysPerWeek,
                    items: List.generate(7, (i) => i + 1)
                        .map((d) =>
                        DropdownMenuItem(value: d, child: Text('$d일')))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _usageDaysPerWeek = value),
                    validator: (v) {
                      if (!_isUnused && v == null) return '선택';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: '하루',
                      border: OutlineInputBorder(),
                    ),
                    value: _usageHoursPerDay,
                    items: List.generate(24, (i) => i + 1)
                        .map((h) => DropdownMenuItem(
                        value: h, child: Text('$h시간')))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _usageHoursPerDay = value),
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
      ],
    );
  }

  Widget _buildPurposeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('주 사용 용도 🎯', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: _purposes
              .map((purpose) => ChoiceChip(
            label: Text(purpose),
            selected: _selectedPurpose == purpose,
            onSelected: (selected) =>
                setState(() => _selectedPurpose = selected ? purpose : null),
          ))
              .toList(),
        ),
        if (_selectedPurpose == null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              '용도를 선택해주세요.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
        if (_selectedPurpose == '기타')
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: TextFormField(
              controller: _otherPurposeController,
              decoration: const InputDecoration(
                labelText: '기타 용도 입력',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (_selectedPurpose == '기타' &&
                    (value == null || value.isEmpty)) {
                  return '기타 용도를 입력해주세요.';
                }
                return null;
              },
            ),
          ),
      ],
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('제품 사진 📸', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          '모든 부품이 함께 찍힌 사진을 추가해주세요.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickImages,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: _images.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo,
                      size: 40, color: Colors.grey[600]),
                  const SizedBox(height: 8),
                  Text(
                    '사진 추가 (최대 5장)',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
                : ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(8),
              itemCount: _images.length,
              itemBuilder: (context, index) {
                final image = _images[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: kIsWeb
                            ? Image.network(
                          image.path,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        )
                            : Image.file(
                          File(image.path),
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _images.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: _isLoading ? null : _submitRequests,
      child: _isLoading
          ? const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        ),
      )
          : const Text('판매 요청 제출'),
    );
  }
}
