import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// --- 모델 및 서비스 import ---
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

  const PcAssemblyScreen({
    super.key,
    this.specProfile,
  });

  @override
  State<PcAssemblyScreen> createState() => _PcAssemblyScreenState();
}

class _PcAssemblyScreenState extends State<PcAssemblyScreen> {
  // --- Services ---
  final CompatibilityService _compatibilityService = CompatibilityService();

  // --- State Variables ---
  // === BasePart를 기본으로 저장 ===
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

  // 각 BasePart에 대해 선택된 Listing 저장
  final Map<PartCategory, Listing?> _selectedListings = {
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

  // --- Logic ---

  double get _totalPrice {
    double total = _selectedListings.values
        .whereType<Listing>()
        .fold(0.0, (sum, listing) => sum + listing.price);
    if (_assemblyRequested) {
      total += 50000; // 조립 공임비
    }
    return total;
  }

  void _showComponentSelectionDialog(PartCategory category) {
    // === BasePart 기반 호환성 체크 ===
    final Map<PartCategory, Part?> currentSelectionForCompat = {};

    // TODO: BasePart를 Part로 변환하는 로직 (호환성 서비스에서 처리)
    // 현재는 간단하게 처리

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${_categoryToString(category)} 선택'),
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
                  return const Center(
                      child: Text('호환되는 부품 모델이 없습니다.'));
                }
                final baseParts = snapshot.data!;
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: baseParts.length,
                  itemBuilder: (context, index) {
                    final basePart = baseParts[index];
                    return ListTile(
                      title: Text(basePart.modelName),
                      subtitle: Text(
                          '매물 ${basePart.listingCount}개 / 최저가 ${NumberFormat('#,###').format(basePart.lowestPrice)}원~'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => _handleBasePartSelection(basePart, category),
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

  Future<void> _handleBasePartSelection(
      BasePart basePart, PartCategory category) async {
    Navigator.pop(context); // 다이얼로그 닫기

    // === BasePart 먼저 저장 (호환성 체크용) ===
    setState(() {
      _selectedComponents[category] = basePart;
    });

    // 가격 히스토리 화면으로 이동하여 구매할 Listing 선택
    final selectedListing = await Navigator.push<Listing?>(
      context,
      MaterialPageRoute(
          builder: (context) => PriceHistoryScreen(basePart: basePart)),
    );

    if (selectedListing != null && mounted) {
      setState(() {
        _selectedListings[category] = selectedListing;
      });
    } else if (mounted) {
      // 취소했으면 BasePart도 제거
      setState(() {
        _selectedComponents[category] = null;
      });
    }
  }

  // --- UI Build ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('나만의 PC 조립'),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildInfoBanner(),
          Expanded(child: _buildComponentList()),
          _buildBottomActionArea(),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      color: Colors.blue.shade50,
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '부품을 선택하면 자동으로 호환성을 체크합니다',
              style: TextStyle(
                color: Colors.blue.shade900,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComponentList() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: _selectedComponents.keys.map((category) {
        final selectedBasePart = _selectedComponents[category];
        final selectedListing = _selectedListings[category];
        final isRequired = category == PartCategory.cpu ||
            category == PartCategory.mainboard ||
            category == PartCategory.ram;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: selectedListing != null
                ? BorderSide(color: Colors.green.shade300, width: 2)
                : BorderSide.none,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getCategoryIcon(category),
                  color: selectedListing != null
                      ? Colors.green
                      : (isRequired ? Colors.red : Colors.grey),
                  size: 32,
                ),
              ],
            ),
            title: Row(
              children: [
                Text(
                  _categoryToString(category),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (isRequired)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '필수',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: selectedBasePart != null && selectedListing != null
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  selectedBasePart.modelName,
                  style: const TextStyle(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '₩${NumberFormat('#,###').format(selectedListing.price)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            )
                : Text(
              isRequired ? '필수 선택' : '선택 안함',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => _showComponentSelectionDialog(category),
              child: Text(selectedListing != null ? '변경' : '선택'),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomActionArea() {
    final selectedCount =
        _selectedListings.values.whereType<Listing>().length;
    final hasRequiredParts = _selectedListings[PartCategory.cpu] != null &&
        _selectedListings[PartCategory.mainboard] != null &&
        _selectedListings[PartCategory.ram] != null;

    return Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CheckboxListTile(
              title: const Text(
                '조립 서비스',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('전문가가 안전하게 조립해드립니다.'),
              value: _assemblyRequested,
              onChanged: (bool? value) =>
                  setState(() => _assemblyRequested = value ?? false),
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.build, color: Colors.orange),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            if (_assemblyRequested)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  '조립 공임비: ₩50,000',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '총 금액',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '₩${NumberFormat('#,###').format(_totalPrice)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
                Text(
                  '$selectedCount개 선택됨',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: hasRequiredParts
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
              onPressed: hasRequiredParts ? _proceedToPayment : null,
              child: Text(
                hasRequiredParts
                    ? '결제하기'
                    : 'CPU, 메인보드, RAM은 필수입니다',
                style: TextStyle(
                  fontSize: hasRequiredParts ? 18 : 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _proceedToPayment() {
    final selectedListings =
    _selectedListings.values.whereType<Listing>().toList();

    final cartItems = selectedListings
        .map((listing) => CartItem(
      productId: listing.listingId,
      productName: listing.modelName,
      price: listing.price.toDouble(),
      quantity: 1,
      imageUrl: listing.imageUrls.isNotEmpty
          ? listing.imageUrls.first
          : '',
      addedAt: Timestamp.now(),
    ))
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          cartItems: cartItems,
          isBundle: _assemblyRequested,
        ),
      ),
    );
  }

  IconData _getCategoryIcon(PartCategory category) {
    switch (category) {
      case PartCategory.cpu:
        return Icons.memory;
      case PartCategory.mainboard:
        return Icons.developer_board;
      case PartCategory.ram:
        return Icons.sd_storage;
      case PartCategory.gpu:
        return Icons.videogame_asset;
      case PartCategory.ssd:
        return Icons.storage;
      case PartCategory.psu:
        return Icons.power;
      case PartCategory.cooler:
        return Icons.ac_unit;
      case PartCategory.pccase:
        return Icons.computer;
    }
  }
}

String _categoryToString(PartCategory category) {
  switch (category) {
    case PartCategory.cpu:
      return 'CPU';
    case PartCategory.mainboard:
      return '메인보드';
    case PartCategory.ram:
      return 'RAM';
    case PartCategory.gpu:
      return '그래픽카드';
    case PartCategory.ssd:
      return 'SSD';
    case PartCategory.psu:
      return '파워';
    case PartCategory.cooler:
      return '쿨러';
    case PartCategory.pccase:
      return '케이스';
  }
}
