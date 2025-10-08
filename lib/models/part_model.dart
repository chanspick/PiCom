import 'package:cloud_firestore/cloud_firestore.dart';

// 1. 확장된 PartCategory Enum
enum PartCategory {
  cpu,
  gpu,
  ssd,
  mainboard,
  ram,
  psu, // Power Supply Unit
  cooler,
  pccase, // PC Case
}

// 2. CPU 메모리 스펙을 위한 클래스
class MemorySpec {
  final String type;
  final int maxSpeedMhz;
  final int channels;

  MemorySpec({
    required this.type,
    required this.maxSpeedMhz,
    required this.channels,
  });

  factory MemorySpec.fromMap(Map<String, dynamic> map) {
    return MemorySpec(
      type: map['type'] ?? '',
      maxSpeedMhz: map['max_speed_mhz']?.toInt() ?? 0,
      channels: map['channels']?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'max_speed_mhz': maxSpeedMhz,
      'channels': channels,
    };
  }
}

// 3. 모든 부품의 기반이 될 추상 클래스
abstract class Part {
  final String partId;
  final PartCategory category;
  final String brand;
  final String modelName;
  final int? referencePrice;
  final String? imageUrl;
  final int? powerConsumptionW;
  final String? generation;
  final String? codename;
  final String? packaging;

  Part({
    required this.partId,
    required this.category,
    required this.brand,
    required this.modelName,
    this.referencePrice,
    this.imageUrl,
    this.powerConsumptionW,
    this.generation,
    this.codename,
    this.packaging,
  });

  // 4. Firestore 데이터를 category에 따라 적절한 객체로 변환
  factory Part.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Part.fromMap(data);
  }

  factory Part.fromMap(Map<String, dynamic> map) {
    final categoryString = map['category'] as String?;
    // 카테고리 정보가 없거나, enum에 정의되지 않은 경우를 안전하게 처리
    final category = PartCategory.values.firstWhere(
      (e) => e.name == categoryString,
      orElse: () => PartCategory.pccase, // 기본값으로 pccase 사용 (임의)
    );

    switch (category) {
      case PartCategory.cpu:
        return CpuPart.fromMap(map);
      // 다른 부품 카테고리 case들을 여기에 추가
      default:
        // 지원하지 않는 카테고리는 GenericPart로 처리하여 앱이 멈추지 않게 함
        return GenericPart.fromMap(map);
    }
  }
}

// 5. Part를 상속받는 CpuPart 클래스
class CpuPart extends Part {
  final String socket;
  final bool hasIntegratedGraphics;
  final int cores;
  final int threads;
  final double baseClockGhz;
  final double boostClockGhz;
  final double l3CacheMb;
  final String? igpuName;
  final int? igpuFreqMhz;
  final MemorySpec memory;
  final bool coolerIncluded;

  CpuPart({
    required super.partId,
    required super.brand,
    required super.modelName,
    super.referencePrice,
    super.imageUrl,
    super.powerConsumptionW,
    super.generation,
    super.codename,
    super.packaging,
    required this.socket,
    required this.hasIntegratedGraphics,
    required this.cores,
    required this.threads,
    required this.baseClockGhz,
    required this.boostClockGhz,
    required this.l3CacheMb,
    this.igpuName,
    this.igpuFreqMhz,
    required this.memory,
    required this.coolerIncluded,
  }) : super(category: PartCategory.cpu);

  factory CpuPart.fromMap(Map<String, dynamic> map) {
    return CpuPart(
      partId: map['part_id'] ?? '',
      brand: map['brand'] ?? '',
      modelName: map['model'] ?? map['modelName'] ?? 'N/A',
      referencePrice: map['reference_price']?.toInt(),
      imageUrl: map['image_url'],
      powerConsumptionW: map['power_consumption_w']?.toInt(),
      generation: map['generation'],
      codename: map['codename'],
      packaging: map['packaging'],
      socket: map['socket'] ?? '',
      hasIntegratedGraphics: map['has_integrated_graphics'] ?? false,
      cores: map['cores']?.toInt() ?? 0,
      threads: map['threads']?.toInt() ?? 0,
      baseClockGhz: map['base_clock_ghz']?.toDouble() ?? 0.0,
      boostClockGhz: map['boost_clock_ghz']?.toDouble() ?? 0.0,
      l3CacheMb: map['l3_cache_mb']?.toDouble() ?? 0.0,
      igpuName: map['igpu_name'],
      igpuFreqMhz: map['igpu_freq_mhz']?.toInt(),
      memory: MemorySpec.fromMap(map['memory'] ?? {}),
      coolerIncluded: map['cooler_included'] ?? false,
    );
  }
}

// 6. 상세 정보가 없는 부품을 위한 GenericPart 클래스 (안전장치)
class GenericPart extends Part {
  GenericPart({
    required super.partId,
    required super.category,
    required super.brand,
    required super.modelName,
    super.referencePrice,
    super.imageUrl,
  });

  factory GenericPart.fromMap(Map<String, dynamic> map) {
    return GenericPart(
      partId: map['part_id'] ?? map['objectID'] ?? '',
      category: PartCategory.values.firstWhere(
            (e) => e.name == map['category'],
        orElse: () => PartCategory.pccase, // Fallback category
      ),
      brand: map['brand'] ?? 'N/A',
      modelName: map['model'] ?? map['modelName'] ?? 'N/A',
      referencePrice: map['reference_price']?.toInt(),
      imageUrl: map['image_url'],
    );
  }
}
