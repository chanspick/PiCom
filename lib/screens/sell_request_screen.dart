import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'search_screen.dart';

class SellRequestScreen extends StatefulWidget {
  const SellRequestScreen({super.key});

  @override
  State<SellRequestScreen> createState() => _SellRequestScreenState();
}

class _SellRequestScreenState extends State<SellRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  // State variables
  String? _selectedCategory;
  final _productNameController = TextEditingController();
  final _purchaseDateController = TextEditingController();
  DateTime? _selectedDate;
  bool _hasWarranty = false;
  final _warrantyMonthsController = TextEditingController();
  int? _usageDaysPerWeek;
  int? _usageHoursPerDay;
  String? _selectedPurpose;
  final _otherPurposeController = TextEditingController(); // 기타 용도 컨트롤러
  String? _estimatedPrice;
  bool _showPrice = false;

  final List<String> _categories = ['CPU', 'GPU', 'RAM', '메인보드', '저장장치', '기타'];
  final List<String> _purposes = ['일상용', '게임용', '개발용', '사무용', '기타'];

  @override
  void dispose() {
    _productNameController.dispose();
    _purchaseDateController.dispose();
    _warrantyMonthsController.dispose();
    _otherPurposeController.dispose(); // 컨트롤러 해제
    super.dispose();
  }

  Future<void> _navigateToSearchScreen() async {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('부품 종류를 먼저 선택해주세요.')),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchScreen(category: _selectedCategory!),
      ),
    );

    if (result != null && result is String) {
      setState(() {
        _productNameController.text = result;
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

  void _requestQuote() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _estimatedPrice = '₩150,000';
        _showPrice = true;
      });
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
            // ... (기존 코드 생략)
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: '부품 종류',
                border: OutlineInputBorder(),
              ),
              items: _categories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedCategory = newValue;
                });
              },
              validator: (value) => value == null ? '부품 종류를 선택해주세요.' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _productNameController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: '제품 모델',
                hintText: '탭하여 부품 검색',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.search),
              ),
              onTap: _navigateToSearchScreen,
              validator: (value) =>
                  (value == null || value.isEmpty) ? '제품 모델을 선택해주세요.' : null,
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
              validator: (value) =>
                  (value == null || value.isEmpty) ? '구매 일자를 선택해주세요.' : null,
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
                padding: const EdgeInsets.only(
                  top: 8.0,
                  left: 16.0,
                  right: 16.0,
                ),
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

            // 5. 사용 빈도
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  '사용 빈도',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Text(
                  '1주일 기준 얼마나 사용하셨나요?',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: '주',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _usageDaysPerWeek,
                    items: List.generate(7, (index) => index + 1)
                        .map(
                          (day) => DropdownMenuItem(
                            value: day,
                            child: Text('$day일'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _usageDaysPerWeek = value;
                      });
                    },
                    validator: (value) => value == null ? '선택' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: '일',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _usageHoursPerDay,
                    items: List.generate(24, (index) => index + 1)
                        .map(
                          (hour) => DropdownMenuItem(
                            value: hour,
                            child: Text('$hour시간'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _usageHoursPerDay = value;
                      });
                    },
                    validator: (value) => value == null ? '선택' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 6. 용도
            const Text(
              '용도',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
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
                      } else {
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
                    if (_selectedPurpose == '기타' &&
                        (value == null || value.isEmpty)) {
                      return '기타 용도를 입력해주세요.';
                    }
                    return null;
                  },
                ),
              ),
            const SizedBox(height: 24),

            // 7. 견적 요청 버튼
            ElevatedButton(
              onPressed: _requestQuote,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: const Text('견적 요청'),
            ),
            const SizedBox(height: 16),

            // 8. 예상 가격 및 배송하기 버튼
            if (_showPrice)
              Column(
                children: [
                  Text('예상 가격', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    _estimatedPrice ?? '',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: 배송하기 화면으로 이동
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 18),
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Theme.of(
                        context,
                      ).colorScheme.onSecondary,
                    ),
                    child: const Text('배송하기'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
