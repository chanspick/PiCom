import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/part_model.dart'; // Import Part model
import 'search_screen.dart';
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

  // State variables
  Part? _selectedPart; // Replaced category and productName controller
  final _purchaseDateController = TextEditingController();
  DateTime? _selectedDate;
  bool _hasWarranty = false;
  final _warrantyMonthsController = TextEditingController();
  int? _usageDaysPerWeek;
  int? _usageHoursPerDay;
  String? _selectedPurpose;
  final _otherPurposeController = TextEditingController();
  final _requestedPriceController = TextEditingController();
  List<File> _images = [];
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  final List<String> _purposes = ['일상용', '게임용', '개발용', '사무용', '기타'];

  @override
  void dispose() {
    _purchaseDateController.dispose();
    _warrantyMonthsController.dispose();
    _otherPurposeController.dispose();
    _requestedPriceController.dispose();
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
                        child: Image.file(_images[index], width: 90, height: 90, fit: BoxFit.cover),
                      );
                    },
                  ),
          ),
        ),
        if (_images.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              '사진을 1장 이상 추가해주세요.',
              style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Future<void> _navigateToSearchScreen() async {
    // The SearchScreen needs to be adapted to return a Part object
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchScreen(),
      ),
    );

    if (result != null && result is Part) {
      setState(() {
        _selectedPart = result;
      });
    }
  }

  Future<void> _selectPurchaseDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2010),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _purchaseDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
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

      await _sellRequestService.createSellRequest(
        part: _selectedPart!, // Pass the selected part
        purchaseDate: _selectedDate!,
        hasWarranty: _hasWarranty,
        warrantyMonthsLeft: _hasWarranty ? int.tryParse(_warrantyMonthsController.text) : null,
        usageFrequency: '주 ${_usageDaysPerWeek}일, 하루 ${_usageHoursPerDay}시간',
        purpose: purpose,
        requestedPrice: int.parse(_requestedPriceController.text),
        images: _images,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('판매 요청')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Replaced Dropdown and TextFormField with a single tappable field
            FormField<Part>(
              builder: (FormFieldState<Part> state) {
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
                        : Text('${_selectedPart!.brand} ${_selectedPart!.modelName}'),
                  ),
                );
              },
              validator: (value) {
                if (_selectedPart == null) {
                  return '제품 모델을 선택해주세요.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _purchaseDateController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: '구매 일자',
                hintText: '탭하여 날짜 선택',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              onTap: () => _selectPurchaseDate(context),
              validator: (value) => (value == null || value.isEmpty) ? '구매 일자를 선택해주세요.' : null,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('AS 기간 남음'),
              value: _hasWarranty,
              onChanged: (bool value) {
                setState(() {
                  _hasWarranty = value;
                });
              },
              secondary: const Icon(Icons.shield_outlined),
            ),
            if (_hasWarranty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 16.0, right: 16.0),
                child: TextFormField(
                  controller: _warrantyMonthsController,
                  decoration: const InputDecoration(
                    labelText: '남은 AS 개월 수',
                    hintText: '예: 12',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (value) {
                    if (_hasWarranty && (value == null || value.isEmpty)) {
                      return '남은 개월 수를 입력해주세요.';
                    }
                    return null;
                  },
                ),
              ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('사용 빈도', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Text('1주일 기준 얼마나 사용하셨나요?', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: '주', border: OutlineInputBorder()),
                    value: _usageDaysPerWeek,
                    items: List.generate(7, (index) => index + 1)
                        .map((day) => DropdownMenuItem(value: day, child: Text('$day일'))).toList(),
                    onChanged: (value) {
                      setState(() { _usageDaysPerWeek = value; });
                    },
                    validator: (value) => value == null ? '선택' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: '일', border: OutlineInputBorder()),
                    value: _usageHoursPerDay,
                    items: List.generate(24, (index) => index + 1)
                        .map((hour) => DropdownMenuItem(value: hour, child: Text('$hour시간'))).toList(),
                    onChanged: (value) {
                      setState(() { _usageHoursPerDay = value; });
                    },
                    validator: (value) => value == null ? '선택' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('용도', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              children: _purposes.map((purpose) {
                return ChoiceChip(
                  label: Text(purpose),
                  selected: _selectedPurpose == purpose,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedPurpose = purpose;
                      }
                      else {
                        _selectedPurpose = null;
                      }
                    });
                  },
                );
              }).toList(),
            ),
            if (_selectedPurpose == '기타')
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: TextFormField(
                  controller: _otherPurposeController,
                  decoration: const InputDecoration(
                    labelText: '기타 용도 입력',
                    hintText: '사용하신 용도를 직접 입력해주세요.',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (_selectedPurpose == '기타' && (value == null || value.isEmpty)) {
                      return '기타 용도를 입력해주세요.';
                    }
                    return null;
                  },
                ),
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _requestedPriceController,
              decoration: const InputDecoration(
                labelText: '희망 판매 가격',
                hintText: '숫자만 입력 (예: 500000)',
                border: OutlineInputBorder(),
                suffixText: '원',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '희망 판매 가격을 입력해주세요.';
                }
                if (int.tryParse(value) == null || int.parse(value) <= 0) {
                  return '유효한 가격을 입력해주세요.';
                }
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
                textStyle: const TextStyle(fontSize: 18),
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
