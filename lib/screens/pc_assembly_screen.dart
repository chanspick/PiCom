// lib/screens/pc_assembly_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../models/part_model.dart';
import '../models/spec_profile.dart';
import '../models/listing_model.dart';
import '../models/base_part_model.dart';
import '../models/cart_item_model.dart';
import '../services/compatibility_service.dart';
import 'product/price_history_screen.dart';
import 'payment_screen.dart';

class PcAssemblyScreen extends StatefulWidget {
  final SpecProfile? specProfile;

  const PcAssemblyScreen({super.key, this.specProfile});

  @override
  State<PcAssemblyScreen> createState() => _PcAssemblyScreenState();
}

class _PcAssemblyScreenState extends State<PcAssemblyScreen> {
  // --- Services ---
  final CompatibilityService _compatibilityService = CompatibilityService();

  // --- State Variables ---
  final Map<PartCategory, Listing?> _selectedComponents = {
    PartCategory.cpu: null,
    PartCategory.mainboard: null,
    PartCategory.ram: null,
    PartCategory.gpu: null,
    PartCategory.ssd: null,
    PartCategory.psu: null,
    PartCategory.cooler: null,
    PartCategory.pccase: null,
  };
  bool _assemblyRequested = false;
  Map<String, Part?> _selectedPartsCache = {}; // 호환성 검사를 위한 Part 객체 캐시

  @override
  void initState() {
    super.initState();
    if (widget.specProfile != null) {
      print('가이드 모드로 시작합니다.');
    } else {
      print('자유 조립 모드로 시작합니다.');
    }
  }

  // --- Logic ---

  // 선택된 Listing들의 총 가격을 계산하는 Getter
  double get _totalPrice {
    double total = _selectedComponents.values
        .where((listing) => listing != null)
        .fold(0.0, (sum, listing) => sum + listing!.price);

    if (_assemblyRequested) {
      total += 50000; // 공임비
    }
    return total;
  }

  // Listing 객체로부터 Part 객체를 가져오는 헬퍼 함수 (캐싱 기능 포함)
  Future<Part?> _getPartForListing(Listing listing) async {
    if (_selectedPartsCache.containsKey(listing.partId)) {
      return _selectedPartsCache[listing.partId];
    }
    final doc = await FirebaseFirestore.instance.collection('parts').doc(listing.partId).get();
    if (doc.exists) {
      final part = Part.fromFirestore(doc);
      _selectedPartsCache[listing.partId] = part;
      return part;
    }
    return null;
  }

  // 부품 선택 다이얼로그를 보여주는 메인 함수
  void _showComponentSelectionDialog(PartCategory category) async {
    // 호환성 검사를 위해 현재 선택된 부품들의 Part 객체를 준비
    Map<String, Part?> currentSelectionForCompat = {};
    for (var entry in _selectedComponents.entries) {
      if (entry.value != null) {
        currentSelectionForCompat[entry.key.name.toLowerCase()] = await _getPartForListing(entry.value!);
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${_categoryToString(category)} 모델 선택'),
          content: SizedBox(
            width: double.maxFinite,
            child: StreamBuilder<List<BasePart>>(
              stream: _compatibilityService.getCompatibleBaseParts(
                category: category,
                currentSelection: currentSelectionForCompat,
                specProfile: widget.specProfile,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('호환되는 부품 모델이 없습니다.'));
                }
                final baseParts = snapshot.data!;
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: baseParts.length,
                  itemBuilder: (context, index) {
                    final basePart = baseParts[index];
                    return ListTile(
                      title: Text(basePart.modelName),
                      subtitle: Text('최저가 ${NumberFormat('#,###').format(basePart.lowestPrice)}원~ / ${basePart.listingCount}개 매물'),
                      onTap: () async {
                        Navigator.pop(context); // 다이얼로그 닫기
                        final selectedListing = await Navigator.push<Listing?>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PriceHistoryScreen(basePart: basePart),
                          ),
                        );
                        if (selectedListing != null) {
                          setState(() {
                            if (_selectedComponents[category] != null) {
                              _selectedPartsCache.remove(_selectedComponents[category]!.partId);
                            }
                            _selectedComponents[category] = selectedListing;
                          });
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  // --- UI Build ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.specProfile != null ? '추천 견적 조립' : '자유 조립'),
      ),
      body: Column(
        children: [
          // 선택된 부품 목록
          Expanded(
            child: ListView(
              children: _selectedComponents.keys.map((category) {
                final selectedListing = _selectedComponents[category];
                return ListTile(
                  title: Text(_categoryToString(category)),
                  subtitle: Text(
                    selectedListing?.modelName ?? '선택되지 않음',
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: ElevatedButton(
                    child: const Text('선택'),
                    onPressed: () => _showComponentSelectionDialog(category),
                  ),
                );
              }).toList(),
            ),
          ),
          // 하단 가격 및 주문 버튼
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                CheckboxListTile(
                  title: const Text('조립 서비스'),
                  subtitle: const Text('전문가가 안전하게 조립해드립니다.'),
                  value: _assemblyRequested,
                  onChanged: (bool? value) => setState(() => _assemblyRequested = value ?? false),
                  secondary: const Text('₩50,000'),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('총액', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('₩${NumberFormat('#,###').format(_totalPrice)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    final selectedListings = _selectedComponents.values.where((l) => l != null).cast<Listing>().toList();
                    if (_selectedComponents[PartCategory.cpu] == null || _selectedComponents[PartCategory.mainboard] == null || _selectedComponents[PartCategory.ram] == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('필수 부품(CPU, 메인보드, RAM)을 모두 선택해주세요.')));
                      return;
                    }
                    final cartItems = selectedListings.map((listing) {
                      return CartItem(
                        productId: listing.listingId,
                        productName: listing.modelName,
                        price: listing.price.toDouble(),
                        quantity: 1,
                        imageUrl: listing.imageUrls.isNotEmpty ? listing.imageUrls.first : '',
                        addedAt: Timestamp.now(),
                      );
                    }).toList();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaymentScreen(
                          cartItems: cartItems,
                          isBundle: _assemblyRequested,
                        ),
                      ),
                    );
                  },
                  child: const Text('이 구성으로 주문하기'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 헬퍼 함수
String _categoryToString(PartCategory category) {
  switch (category) {
    case PartCategory.cpu: return 'CPU';
    case PartCategory.mainboard: return '메인보드';
    case PartCategory.ram: return 'RAM';
    case PartCategory.gpu: return '그래픽카드';
    case PartCategory.ssd: return 'SSD';
    case PartCategory.psu: return '파워 서플라이';
    case PartCategory.cooler: return 'CPU 쿨러';
    case PartCategory.pccase: return '케이스';
  }
}