// lib/screens/product/finished_pc_pricing_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../models/listing_model.dart';
import '../../models/part_model.dart'; // Part 모델 import
import '../../models/sell_request_model.dart';
import '../../services/sell_request_service.dart';

// +++ [추가] 가격 입력 필드를 위한 숫자 포맷터 +++
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }
    final int value = int.parse(newValue.text);
    final formatter = NumberFormat.decimalPattern('ko_KR');
    final String newText = formatter.format(value);
    return newValue.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length));
  }
}

class FinishedPcPricingScreen extends StatefulWidget {
  // [핵심 수정] 생성자에서 List<Listing> 대신 List<Part>를 받습니다.
  final List<Part> selectedParts;

  const FinishedPcPricingScreen({
    super.key,
    required this.selectedParts,
  });

  @override
  State<FinishedPcPricingScreen> createState() => _FinishedPcPricingScreenState();
}

class _FinishedPcPricingScreenState extends State<FinishedPcPricingScreen> {
  // --- 서비스, 키, 컨트롤러, 상태 변수는 이전과 거의 동일 ---
  final _formKey = GlobalKey<FormState>();
  final _sellRequestService = SellRequestService();

  final _totalPriceController = TextEditingController();
  late List<TextEditingController> _partPriceControllers;
  final _yearController = TextEditingController();
  final _monthController = TextEditingController();
  final _warrantyMonthsController = TextEditingController();
  final _otherPurposeController = TextEditingController();

  int _totalPrice = 0;
  int _distributedPrice = 0;
  bool _isLoading = false;

  List<File> _images = [];
  final ImagePicker _picker = ImagePicker();
  AgeInfoType _ageInfoType = AgeInfoType.unknown;
  bool _isSecondHand = false;
  bool _hasWarranty = false;
  bool _isUnused = false;
  int? _usageDaysPerWeek;
  int? _usageHoursPerDay;
  String? _selectedPurpose;
  final List<String> _purposes = ['일상용', '게임용', '개발용', '사무용', '기타'];

  @override
  void initState() {
    super.initState();
    // [수정] selectedListings 대신 selectedParts를 기준으로 컨트롤러 생성
    _partPriceControllers =
        List.generate(widget.selectedParts.length, (index) => TextEditingController());
    _totalPriceController.addListener(_updatePrices);
    for (var controller in _partPriceControllers) {
      controller.addListener(_updatePrices);
    }
  }

  @override
  void dispose() {
    _totalPriceController.dispose();
    _yearController.dispose();
    _monthController.dispose();
    _warrantyMonthsController.dispose();
    _otherPurposeController.dispose();
    for (var controller in _partPriceControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // --- 메서드 로직 (수정된 부분 위주로 설명) ---

  void _updatePrices() {
    if (mounted) {
      setState(() {
        _totalPrice = int.tryParse(_totalPriceController.text.replaceAll(',', '')) ?? 0;
        _distributedPrice = _partPriceControllers.fold(0, (sum, controller) {
          return sum + (int.tryParse(controller.text.replaceAll(',', '')) ?? 0);
        });
      });
    }
  }

  bool _arePricesValid() {
    return _totalPrice > 0 && _totalPrice == _distributedPrice;
  }

  Future<void> _pickImages() async {
    final List<XFile>? pickedFiles = await _picker.pickMultiImage(imageQuality: 70, maxWidth: 1000);
    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      setState(() => _images = pickedFiles.map((file) => File(file.path)).toList());
    }
  }

  Future<void> _submitSellRequests() async {
    if (!_formKey.currentState!.validate() || !_arePricesValid() || _images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('모든 필수 정보를 정확하게 입력해주세요.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // [핵심 수정] 더 이상 Listing에서 Part를 억지로 만들 필요가 없습니다.
      // 위젯이 처음부터 올바른 Part 객체 리스트를 가지고 있기 때문입니다.
      final partsToSell = <PartToSell>[];
      for (int i = 0; i < widget.selectedParts.length; i++) {
        final part = widget.selectedParts[i];
        final price = int.parse(_partPriceControllers[i].text.replaceAll(',', ''));
        partsToSell.add(PartToSell(part: part, price: price));
      }

      final String usageFrequency = _isUnused ? '미사용' : '주 ${_usageDaysPerWeek}일, 하루 ${_usageHoursPerDay}시간';
      String purpose = _selectedPurpose!;
      if (purpose == '기타') {
        purpose = _otherPurposeController.text;
      }

      await _sellRequestService.createSellRequestsFromFinishedPc(
        partsToSell: partsToSell,
        images: _images,
        ageInfoType: _ageInfoType,
        ageInfoYear: _ageInfoType != AgeInfoType.unknown ? int.tryParse(_yearController.text) : null,
        ageInfoMonth: _ageInfoType != AgeInfoType.unknown ? int.tryParse(_monthController.text) : null,
        isSecondHand: _isSecondHand,
        usageFrequency: usageFrequency,
        purpose: purpose,
        hasWarranty: _hasWarranty,
        warrantyMonthsLeft: _hasWarranty ? int.tryParse(_warrantyMonthsController.text) : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('완제품 판매 요청이 성공적으로 등록되었습니다.')));
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류 발생: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- UI 빌더 ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('가격 및 정보 입력')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildPriceSection(),
            const Divider(height: 40),
            _buildCommonInfoSection(),
            const SizedBox(height: 24),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSection() {
    final currencyFormat = NumberFormat.decimalPattern('ko_KR');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("가격 설정 💸", style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text('판매하고자 하는 총 금액을 각 부품에 분배해주세요.', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 16),
        TextFormField(
          controller: _totalPriceController,
          decoration: const InputDecoration(labelText: '총 희망 판매가', border: OutlineInputBorder()),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()],
          validator: (v) => (v == null || v.isEmpty || int.tryParse(v.replaceAll(',', ''))! <= 0) ? '총액을 입력하세요.' : null,
        ),
        const SizedBox(height: 16),
        // [수정] widget.selectedParts를 사용하여 가격 입력 필드를 동적으로 생성
        ...List.generate(widget.selectedParts.length, (index) {
          final part = widget.selectedParts[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: TextFormField(
              controller: _partPriceControllers[index],
              decoration: InputDecoration(labelText: '${part.modelName} 가격', border: const OutlineInputBorder()),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()],
              validator: (v) => (v == null || v.isEmpty) ? '가격을 입력하세요.' : null,
            ),
          );
        }),
        const SizedBox(height: 16),
        // 가격 검증 UI는 변경 없음
        Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: _arePricesValid() ? Colors.blue.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _arePricesValid() ? Colors.blue.shade200 : Colors.orange.shade200)
            ),
            child: Column(
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('목표 총액:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('${currencyFormat.format(_totalPrice)} 원'),
                  ]),
                  const SizedBox(height: 4),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('분배된 총액:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      '${currencyFormat.format(_distributedPrice)} 원',
                      style: TextStyle(color: _arePricesValid() ? Colors.blue : Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ]),
                  if (!_arePricesValid() && _totalPrice > 0 && _distributedPrice > 0) ...[
                    const Divider(height: 12, color: Colors.transparent),
                    Text(
                      '남은 금액: ${currencyFormat.format(_totalPrice - _distributedPrice)} 원',
                      style: TextStyle(color: Colors.red.shade700),
                    )
                  ]
                ]
            )
        ),
      ],
    );
  }
  Widget _buildCommonInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("제품 공통 정보 📝", style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text('모든 부품에 동일하게 적용될 정보를 입력합니다.', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 16),

        // --- 이미지 피커 ---
        const Text('제품 사진 (최대 5장)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildImagePicker(),

        // --- 연식 정보 (SellRequestScreen에서 가져옴) ---
        _buildAgeInfoSection(),

        // --- 소유 이력 (SellRequestScreen에서 가져옴) ---
        _buildOwnershipSection(),

        // --- AS 기간 ---
        SwitchListTile(
          title: const Text('AS 기간 남음'),
          value: _hasWarranty,
          onChanged: (bool value) => setState(() => _hasWarranty = value),
          secondary: const Icon(Icons.shield_outlined),
        ),
        if (_hasWarranty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 16.0, right: 16.0, bottom: 8.0),
            child: TextFormField(
              controller: _warrantyMonthsController,
              decoration: const InputDecoration(labelText: '남은 AS 개월 수', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (_hasWarranty && (value == null || value.isEmpty)) return '개월 수를 입력해주세요.';
                return null;
              },
            ),
          ),

        // --- 사용 빈도 (SellRequestScreen에서 가져옴) ---
        const SizedBox(height: 16),
        const Text('사용 빈도', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        _buildUsageFrequencySection(),

        // --- 주 사용 용도 (SellRequestScreen에서 가져옴) ---
        const SizedBox(height: 16),
        const Text('주 사용 용도', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildPurposeSection(),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          backgroundColor: _arePricesValid() ? Theme.of(context).primaryColor : Colors.grey,
          foregroundColor: Colors.white
      ),
      onPressed: _arePricesValid() && !_isLoading ? _submitSellRequests : null,
      child: _isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text('최종 판매 요청 제출'),
    );
  }

  // --- 상세 정보 입력을 위한 헬퍼 위젯들 (SellRequestScreen에서 재활용) ---

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: _images.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.camera_alt, color: Colors.grey[600]),
          Text('사진 추가', style: TextStyle(color: Colors.grey[600])),
        ]))
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
    );
  }

  Widget _buildAgeInfoSection() {
    // ... SellRequestScreen의 _buildAgeInfoSection() 내용을 그대로 붙여넣습니다 ...
    // (UI 일관성을 위해 코드를 그대로 가져와 사용)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text('부품 연식 정보', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        RadioListTile<AgeInfoType>(
          title: const Text('최초 신품 구매일'),
          value: AgeInfoType.originalPurchaseDate,
          groupValue: _ageInfoType,
          onChanged: (value) => setState(() => _ageInfoType = value!),
        ),
        RadioListTile<AgeInfoType>(
          title: const Text('제조년월'),
          value: AgeInfoType.manufactureDate,
          groupValue: _ageInfoType,
          onChanged: (value) => setState(() => _ageInfoType = value!),
        ),
        RadioListTile<AgeInfoType>(
          title: const Text('정보 없음'),
          value: AgeInfoType.unknown,
          groupValue: _ageInfoType,
          onChanged: (value) => setState(() => _ageInfoType = value!),
        ),
        if (_ageInfoType != AgeInfoType.unknown)
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
                      if (_ageInfoType != AgeInfoType.unknown && (value == null || value.isEmpty || value.length < 4)) return '4자리 년도';
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
                      if (_ageInfoType != AgeInfoType.unknown) {
                        if (value == null || value.isEmpty) return '월 입력';
                        final month = int.tryParse(value);
                        if (month == null || month < 1 || month > 12) return '1-12';
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
    // ... SellRequestScreen의 _buildOwnershipSection() 내용을 그대로 붙여넣습니다 ...
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text('소유 이력', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        RadioListTile<bool>(
          title: const Text('제가 신품으로 직접 구매했어요.'),
          value: false, // isSecondHand = false
          groupValue: _isSecondHand,
          onChanged: (value) => setState(() => _isSecondHand = value!),
        ),
        RadioListTile<bool>(
          title: const Text('저도 중고로 구매했어요.'),
          value: true, // isSecondHand = true
          groupValue: _isSecondHand,
          onChanged: (value) => setState(() => _isSecondHand = value!),
        ),
      ],
    );
  }

  Widget _buildUsageFrequencySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }

  Widget _buildPurposeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8.0,
          children: _purposes.map((purpose) => ChoiceChip(
            label: Text(purpose),
            selected: _selectedPurpose == purpose,
            onSelected: (selected) => setState(() => _selectedPurpose = selected ? purpose : null),
          )).toList(),
        ),
        // validator가 FormField 내부에 있어야 하므로 FormField로 감싸줍니다.
        FormField(
          builder: (state) {
            if (_selectedPurpose == null) {
              return Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text('용도를 선택해주세요.', style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
              );
            }
            return const SizedBox.shrink();
          },
          validator: (_) => _selectedPurpose == null ? '용도를 선택해주세요.' : null,
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
      ],
    );
  }
}