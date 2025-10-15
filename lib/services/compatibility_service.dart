// lib/services/compatibility_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/part_model.dart';
import '../models/base_part_model.dart';
import '../models/spec_profile.dart';

class CompatibilityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 현재 선택된 부품 조합을 기반으로 호환되는 BasePart 목록을 스트리밍합니다.
  Stream<List<BasePart>> getCompatibleBaseParts({
    required PartCategory category,
    required Map<PartCategory, Part?> currentSelection, // [수정] Map의 Key 타입을 String에서 PartCategory로 변경
    SpecProfile? specProfile,
  }) {
    // 'base_parts' 컬렉션을 기본 쿼리 대상으로 설정합니다.
    // base_parts 문서에는 호환성 필터링을 위한 주요 스펙이 denormalized 되어 있어야 합니다. (예: socket, memoryType 등)
    Query query = _firestore
        .collection('base_parts')
        .where('category', isEqualTo: category.name)
        .where('listingCount', isGreaterThan: 0);

    // --- ⚙️ 지능형 호환성 필터링 로직 ---

    // 1. 메인보드를 선택할 경우: 현재 선택된 CPU의 소켓과 일치하는 메인보드를 찾습니다.
    if (category == PartCategory.mainboard) {
      final cpu = currentSelection[PartCategory.cpu] as CpuPart?;
      if (cpu != null && cpu.socket.isNotEmpty) {
        print('LOG: Filtering mainboards for CPU socket: ${cpu.socket}');
        query = query.where('socket', isEqualTo: cpu.socket);
      }
    }

    // 2. RAM을 선택할 경우: 현재 선택된 메인보드의 메모리 타입과 일치하는 RAM을 찾습니다.
    if (category == PartCategory.ram) {
      final mainboard = currentSelection[PartCategory.mainboard] as MainboardPart?;
      if (mainboard != null && mainboard.memoryType.isNotEmpty) {
        print('LOG: Filtering RAM for memory type: ${mainboard.memoryType}');
        // 'base_parts'의 RAM 문서에 'memoryType' 필드가 있어야 합니다. (예: "DDR4", "DDR5")
        query = query.where('memoryType', isEqualTo: mainboard.memoryType);
      }
    }

    // 3. CPU를 선택할 경우: 현재 선택된 메인보드의 소켓과 일치하는 CPU를 찾습니다.
    if (category == PartCategory.cpu) {
      final mainboard = currentSelection[PartCategory.mainboard] as MainboardPart?;
      if (mainboard != null && mainboard.socket.isNotEmpty) {
        print('LOG: Filtering CPUs for mainboard socket: ${mainboard.socket}');
        query = query.where('socket', isEqualTo: mainboard.socket);
      }
    }

    // [확장 제안] 향후 아래와 같은 규칙들을 추가할 수 있습니다.
    // - 케이스(pccase) 선택 시: 메인보드 폼팩터(formFactor)와 맞는 케이스 필터링
    // - 파워(psu) 선택 시: CPU, GPU의 TDP 합을 고려한 추천 용량 필터링
    // - CPU 쿨러 선택 시: CPU 소켓과 맞는 쿨러 필터링

    return query.snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        print('LOG: No compatible parts found for category: ${category.name}');
      }
      return snapshot.docs
          .map((doc) => BasePart.fromFirestore(doc))
          .toList();
    });
  }
}