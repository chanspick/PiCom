// lib/services/compatibility_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/part_model.dart';
import '../models/base_part_model.dart';
import '../models/spec_profile.dart';

class CompatibilityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<BasePart>> getCompatibleBaseParts({
    required PartCategory category,
    required Map<String, Part?> currentSelection,
    SpecProfile? specProfile,
  }) {
    Query query = _firestore
        .collection('base_parts')
        .where('category', isEqualTo: category.name)
        .where('listingCount', isGreaterThan: 0);

    // TODO: 여기에 호환성 필터링 로직을 추가합니다.
    // final selectedCpu = currentSelection['cpu'] as CpuPart?;
    // if (category == PartCategory.mainboard && selectedCpu != null) {
    //   // 이 부분은 더 복잡한 로직이 필요합니다. (예: 호환되는 칩셋 목록 조회 후 쿼리)
    // }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => BasePart.fromFirestore(doc))
          .toList();
    });
  }
}