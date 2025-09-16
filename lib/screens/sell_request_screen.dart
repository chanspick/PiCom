
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

  final List<String> _categories = ['CPU', 'GPU', 'RAM', '메인보드', '저장장치', '기타'];

  @override
  void dispose() {
    _productNameController.dispose();
    _purchaseDateController.dispose();
    _warrantyMonthsController.dispose();
    super.dispose();
  }

  // 부품 검색 화면으로 이동하고 결과를 받아오는 함수
  Future<void> _navigateToSearchScreen() async {
    // SearchScreen으로 이동하고 결과를 기다림
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchScreen()),
    );

    // 결과가 있으면 컨트롤러에 텍스트 설정
    if (result != null && result is String) {
      setState(() {
        _productNameController.text = result;
      });
    }
  }

  // 달력을 표시하고 날짜를 선택하는 함수
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('판매 요청'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // 1. 부품 분류
            DropdownButtonFormField<String>(
              value: _selectedCategory,
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

            // 2. 상세 부품 선택
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
              validator: (value) => (value == null || value.isEmpty) ? '제품 모델을 선택해주세요.' : null,
            ),
            const SizedBox(height: 16),

            // 3. 구매 일자
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

            // 4. AS 기간 유무
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
                    FilteringTextInputFormatter.digitsOnly
                  ],
                  validator: (value) {
                    if (_hasWarranty && (value == null || value.isEmpty)) {
                      return '남은 개월 수를 입력해주세요.';
                    }
                    return null;
                  },
                ),
              ),
            const SizedBox(height: 24),
            // TODO: 다른 입력 필드 추가
          ],
        ),
      ),
    );
  }
}
