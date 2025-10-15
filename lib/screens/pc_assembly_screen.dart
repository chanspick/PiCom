import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// --- 모델 및 서비스 import ---
import '../../models/part_model.dart';
import '../../models/spec_profile.dart';
import '../../models/listing_model.dart';
import '../../models/base_part_model.dart';
import '../../models/cart_item_model.dart';
import '../../services/compatibility_service.dart';
import 'product/finished_pc_pricing_screen.dart';
import 'product/price_history_screen.dart';
import 'payment_screen.dart';

enum AssemblyMode { build, sell }

class PcAssemblyScreen extends StatefulWidget {
  final SpecProfile? specProfile;
  final AssemblyMode mode;

  const PcAssemblyScreen({
    super.key,
    this.specProfile,
    required this.mode,
  });

  @override
  State<PcAssemblyScreen> createState() => _PcAssemblyScreenState();
}

class _PcAssemblyScreenState extends State<PcAssemblyScreen> {
  // --- Services ---
  final CompatibilityService _compatibilityService = CompatibilityService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- State Variables ---
  // [수정] Map<PartCategory, dynamic>으로 하여 Part 또는 Listing 객체를 저장
  final Map<PartCategory, dynamic> _selectedComponents = {
    PartCategory.cpu: null, PartCategory.mainboard: null, PartCategory.ram: null,
    PartCategory.gpu: null, PartCategory.ssd: null, PartCategory.psu: null,
    PartCategory.cooler: null, PartCategory.pccase: null,
  };

  // 구매(build) 모드 전용 상태 변수
  bool _assemblyRequested = false;

  // --- Logic ---

  // 구매(build) 모드 전용 총액 계산 getter
  double get _totalPrice {
    double total = _selectedComponents.values
        .where((component) => component is Listing)
        .fold(0.0, (sum, listing) => sum + (listing as Listing).price);
    if (_assemblyRequested) {
      total += 50000; // 공임비
    }
    return total;
  }

  void _showComponentSelectionDialog(PartCategory category) {
    final Map<PartCategory, Part?> currentSelectionForCompat = {};
    _selectedComponents.forEach((key, value) {
      if (value is Part) {
        currentSelectionForCompat[key] = value;
      }
    });

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
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
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
                      subtitle: Text('매물 ${basePart.listingCount}개 / 최저가 ${NumberFormat('#,###').format(basePart.lowestPrice)}원~'),
                      onTap: () {
                        if (widget.mode == AssemblyMode.sell) {
                          _handlePartSelectionForSell(basePart, category);
                        } else {
                          _handlePartSelectionForBuild(basePart);
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

  Future<void> _handlePartSelectionForSell(BasePart basePart, PartCategory category) async {
    Navigator.pop(context); // 다이얼로그 닫기
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      final doc = await _firestore.collection('parts').doc(basePart.basePartId).get();
      if (doc.exists) {
        final selectedPart = Part.fromFirestore(doc);
        setState(() => _selectedComponents[category] = selectedPart);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${basePart.modelName}의 상세 정보를 찾을 수 없습니다.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('정보 로딩 중 오류 발생: $e')));
    } finally {
      Navigator.pop(context); // 로딩 인디케이터 닫기
    }
  }

  Future<void> _handlePartSelectionForBuild(BasePart basePart) async {
    Navigator.pop(context); // 다이얼로그 닫기
    final selectedListing = await Navigator.push<Listing?>(
      context,
      MaterialPageRoute(builder: (context) => PriceHistoryScreen(basePart: basePart)),
    );
    if (selectedListing != null) {
      setState(() {
        final category = PartCategory.values.firstWhere((e) => e.name == basePart.category);
        _selectedComponents[category] = selectedListing;
      });
    }
  }

  // --- UI Build ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.mode == AssemblyMode.build ? 'PC 조립' : '판매할 PC 구성')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: _selectedComponents.keys.map((category) {
                final selectedComponent = _selectedComponents[category];
                String modelName = '선택되지 않음';
                if (selectedComponent is Part) modelName = selectedComponent.modelName;
                if (selectedComponent is Listing) modelName = selectedComponent.modelName;

                return ListTile(
                  title: Text(_categoryToString(category)),
                  subtitle: Text(modelName, overflow: TextOverflow.ellipsis),
                  trailing: ElevatedButton(
                    child: const Text('선택'),
                    onPressed: () => _showComponentSelectionDialog(category),
                  ),
                );
              }).toList(),
            ),
          ),
          _buildBottomActionArea(),
        ],
      ),
    );
  }

  Widget _buildBottomActionArea() {
    if (widget.mode == AssemblyMode.build) {
      return _buildOrderActionArea();
    } else {
      return _buildSellActionArea();
    }
  }

  Widget _buildSellActionArea() {
    final selectedParts = _selectedComponents.values.whereType<Part>().toList();
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          if (selectedParts.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('판매할 부품을 하나 이상 선택해주세요.')));
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => FinishedPcPricingScreen(selectedParts: selectedParts)),
          );
        },
        child: const Text('다음 (가격 및 정보 입력)'),
      ),
    );
  }

  Widget _buildOrderActionArea() {
    return Padding(
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
              final selectedListings = _selectedComponents.values.whereType<Listing>().toList();
              if (_selectedComponents[PartCategory.cpu] == null || _selectedComponents[PartCategory.mainboard] == null || _selectedComponents[PartCategory.ram] == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('필수 부품(CPU, 메인보드, RAM)을 모두 선택해주세요.')));
                return;
              }
              final cartItems = selectedListings.map((listing) => CartItem(
                productId: listing.listingId, productName: listing.modelName,
                price: listing.price.toDouble(), quantity: 1,
                imageUrl: listing.imageUrls.isNotEmpty ? listing.imageUrls.first : '',
                addedAt: Timestamp.now(),
              )).toList();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PaymentScreen(cartItems: cartItems, isBundle: _assemblyRequested)),
              );
            },
            child: const Text('이 구성으로 주문하기'),
          ),
        ],
      ),
    );
  }
}

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
