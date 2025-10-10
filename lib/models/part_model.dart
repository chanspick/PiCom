import 'package:cloud_firestore/cloud_firestore.dart';

/// ==================== 공용 유틸 ====================

T? _cast<T>(dynamic v) => (v is T) ? v : null;
num? _asNum(dynamic v) {
  if (v == null) return null;
  if (v is num) return v;
  if (v is String) return num.tryParse(v);
  return null;
}
int? _asInt(dynamic v) => _asNum(v)?.toInt();
double? _asDouble(dynamic v) => _asNum(v)?.toDouble();
String? _asString(dynamic v) => v?.toString();

String _slug(String s) => s.toLowerCase().replaceAll(RegExp(r'\s+'), '-');

String _ifaceToString({dynamic type, dynamic version, dynamic lanes}) {
  final t = _asString(type)?.trim();
  final v = _asString(version)?.trim();
  final l0 = lanes == null ? null : (_asInt(lanes) ?? _asString(lanes));
  final l = l0 == null || l0.toString().isEmpty ? null : 'x$l0';
  final parts = <String?>[t, v, l].whereType<String>().where((s) => s.isNotEmpty).toList();
  return parts.join(' ');
}

/// ==================== 카테고리 ====================

enum PartCategory { cpu, gpu, ssd, mainboard, ram, psu, cooler, pccase }

PartCategory _parseCategory(dynamic raw) {
  final s = (_asString(raw) ?? '').toLowerCase();
  if (s == 'motherboard' || s == 'mb') return PartCategory.mainboard;
  return PartCategory.values.firstWhere(
        (e) => e.name == s,
    orElse: () => PartCategory.pccase,
  );
}

/// ==================== MemorySpec ====================

class MemorySpec {
  final String type;
  final int maxSpeedMhz;
  final int channels;

  const MemorySpec({
    required this.type,
    required this.maxSpeedMhz,
    required this.channels,
  });

  factory MemorySpec.fromMap(Map<String, dynamic>? map) {
    final m = map ?? const {};
    return MemorySpec(
      type: _asString(m['type']) ?? '',
      maxSpeedMhz: _asInt(m['max_speed_mhz']) ?? _asInt(m['maxSpeedMhz']) ?? 0,
      channels: _asInt(m['channels']) ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'type': type,
    'maxSpeedMhz': maxSpeedMhz,
    'channels': channels,
  };
}

/// ==================== 공통 Part 베이스 ====================

abstract class Part {
  final String partId; // 필수
  final PartCategory category;
  final String brand;
  final String modelName;

  final int? referencePrice;     // KRW
  final String? imageUrl;
  final int? powerConsumptionW;

  final String? generation;
  final String? codename;
  final String? packaging;

  const Part({
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

  /// Firestore 문서 → Part (doc.id를 partId fallback으로)
  factory Part.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>? ?? {});
    data.putIfAbsent('partId', () => data['part_id'] ?? doc.id);
    return Part.fromMap(data);
  }

  /// 관대한 입력 → 구체 타입으로 분기
  factory Part.fromMap(Map<String, dynamic> map) {
    final category = _parseCategory(map['category']);
    switch (category) {
      case PartCategory.cpu:
        return CpuPart.fromMap(map);
      case PartCategory.gpu:
        return GpuPart.fromMap(map);
      case PartCategory.mainboard:
        return MainboardPart.fromMap(map);
      default:
        return GenericPart.fromMap(map);
    }
  }

  /// 저장/색인 공통 스키마 (camelCase)
  Map<String, dynamic> toMap() => {
    'partId': partId,
    'category': category.name,
    'brand': brand,
    'modelName': modelName,
    'referencePrice': referencePrice,
    'imageUrl': imageUrl,
    'powerConsumptionW': powerConsumptionW,
    'generation': generation,
    'codename': codename,
    'packaging': packaging,
  };

  /// Algolia 최소 오브젝트 (원하면 사용)
  Map<String, dynamic> toAlgoliaObject() => {
    'objectID': partId,
    'partId': partId,
    'category': category.name,
    'brand': brand,
    'modelName': modelName,
    'referencePrice': referencePrice,
  };
}

/// ==================== CPU ====================

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

  const CpuPart({
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

  static String _genId(Map<String, dynamic> map) {
    final brand = _slug(_asString(map['brand']) ?? 'unknown');
    final model = _slug(_asString(map['model'] ?? map['modelName'] ?? map['name']) ?? 'unknown');
    final code  = _slug(_asString(map['codename']) ?? 'unknown');
    return 'cpu-$brand-$code-$model';
  }

  factory CpuPart.fromMap(Map<String, dynamic> map) {
    final partId = _asString(map['partId']) ?? _asString(map['part_id']) ?? _genId(map);
    return CpuPart(
      partId: partId,
      brand: _asString(map['brand']) ?? 'N/A',
      modelName: _asString(map['model'] ?? map['modelName'] ?? map['name']) ?? 'N/A',
      referencePrice: _asInt(map['reference_price'] ?? map['price'] ?? map['pricing']?['basePrice']),
      imageUrl: _asString(map['image_url'] ?? map['imageUrl']),
      powerConsumptionW: _asInt(map['power_consumption_w'] ?? map['powerConsumptionW']),
      generation: _asString(map['generation']),
      codename: _asString(map['codename']),
      packaging: _asString(map['packaging']),
      socket: _asString(map['socket']) ?? '',
      hasIntegratedGraphics: (map['has_integrated_graphics'] ?? map['hasIntegratedGraphics']) == true,
      cores: _asInt(map['cores']) ?? 0,
      threads: _asInt(map['threads']) ?? 0,
      baseClockGhz: _asDouble(map['base_clock_ghz'] ?? map['baseClockGhz']) ?? 0.0,
      boostClockGhz: _asDouble(map['boost_clock_ghz'] ?? map['boostClockGhz']) ?? 0.0,
      l3CacheMb: _asDouble(map['l3_cache_mb'] ?? map['l3CacheMb']) ?? 0.0,
      igpuName: _asString(map['igpu_name'] ?? map['igpuName']),
      igpuFreqMhz: _asInt(map['igpu_freq_mhz'] ?? map['igpuFreqMhz']),
      memory: MemorySpec.fromMap(_cast<Map<String, dynamic>>(map['memory']) ?? const {}),
      coolerIncluded: (map['cooler_included'] ?? map['coolerIncluded']) == true,
    );
  }

  @override
  Map<String, dynamic> toMap() => {
    ...super.toMap(),
    'socket': socket,
    'hasIntegratedGraphics': hasIntegratedGraphics,
    'cores': cores,
    'threads': threads,
    'baseClockGhz': baseClockGhz,
    'boostClockGhz': boostClockGhz,
    'l3CacheMb': l3CacheMb,
    'igpuName': igpuName,
    'igpuFreqMhz': igpuFreqMhz,
    'memory': memory.toMap(),
    'coolerIncluded': coolerIncluded,
  };
}

/// ==================== GPU ====================

class GpuPart extends Part {
  final String chipset;        // e.g., "RTX 3060"
  final int memorySizeGb;      // e.g., 12
  final String memoryType;     // e.g., "GDDR6"
  final String? interfaceType; // e.g., "PCIe 4.0 x16"
  final int? boostClockMhz;
  final int? cudaCores;
  final int? tdpW;

  const GpuPart({
    required super.partId,
    required super.brand,
    required super.modelName,
    super.referencePrice,
    super.imageUrl,
    super.powerConsumptionW,
    super.generation,
    super.codename,
    super.packaging,
    required this.chipset,
    required this.memorySizeGb,
    required this.memoryType,
    this.interfaceType,
    this.boostClockMhz,
    this.cudaCores,
    this.tdpW,
  }) : super(category: PartCategory.gpu);

  static String _genId(Map<String, dynamic> map) {
    final brand = _slug(_asString(map['brand']) ?? 'unknown');
    final model = _slug(_asString(map['chipset']?['model']) ?? _asString(map['model']) ?? _asString(map['name']) ?? 'unknown');
    final memGb = _asInt(map['memory']?['size_gb']) ?? _asInt(map['memorySizeGb']) ?? 0;
    final memTy = _slug(_asString(map['memory']?['type']) ?? _asString(map['memoryType']) ?? 'unknown');
    return 'gpu-$brand-$model-${memGb}gb-$memTy';
  }

  factory GpuPart.fromMap(Map<String, dynamic> map) {
    final partId = _asString(map['partId']) ?? _asString(map['part_id']) ?? _genId(map);

    final memory   = _cast<Map<String, dynamic>>(map['memory']);
    final chipset  = _cast<Map<String, dynamic>>(map['chipset']);
    final iface    = _cast<Map<String, dynamic>>(map['interface']);
    final clocks   = _cast<Map<String, dynamic>>(map['clock_speeds']);
    final power    = _cast<Map<String, dynamic>>(map['power']);

    return GpuPart(
      partId: partId,
      brand: _asString(map['brand']) ?? 'N/A',
      modelName: _asString(map['name'] ?? map['model'] ?? map['modelName']) ?? 'N/A',
      referencePrice: _asInt(map['price'] ?? map['reference_price'] ?? map['pricing']?['basePrice']),
      imageUrl: _asString(map['image_url'] ?? map['imageUrl']),
      powerConsumptionW: _asInt(power?['recommended_psu_watt'] ?? map['powerConsumptionW']),
      chipset: _asString(chipset?['model']) ?? '',
      memorySizeGb: _asInt(memory?['size_gb']) ?? 0,
      memoryType: _asString(memory?['type']) ?? '',
      interfaceType: _ifaceToString(
        type: iface?['type'],
        version: iface?['version'],
        lanes: iface?['lanes'],
      ),
      boostClockMhz: _asInt(clocks?['boost_mhz']),
      cudaCores: _asInt(chipset?['cuda_cores']),
      tdpW: _asInt(map['tdpW'] ?? map['specs']?['tdpW']),
    );
  }

  @override
  Map<String, dynamic> toMap() => {
    ...super.toMap(),
    'chipset': chipset,
    'memorySizeGb': memorySizeGb,
    'memoryType': memoryType,
    'interfaceType': interfaceType,
    'boostClockMhz': boostClockMhz,
    'cudaCores': cudaCores,
    'tdpW': tdpW,
  };
}

/// ==================== 메인보드 ====================

class MainboardPart extends Part {
  final String socket;
  final String chipset;
  final String formFactor; // ATX, Micro-ATX, Mini-ITX
  final int memorySlots;
  final int maxMemoryGb;
  final String memoryType; // DDR4, DDR5
  final int pcieSlots;
  final int sataPorts;
  final int m2Slots;

  const MainboardPart({
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
    required this.chipset,
    required this.formFactor,
    required this.memorySlots,
    required this.maxMemoryGb,
    required this.memoryType,
    required this.pcieSlots,
    required this.sataPorts,
    required this.m2Slots,
  }) : super(category: PartCategory.mainboard);

  static String _genId(Map<String, dynamic> map) {
    final brand = _slug(_asString(map['brand']) ?? 'unknown');
    final name  = _slug(_asString(map['name'] ?? map['model'] ?? map['modelName']) ?? 'unknown');
    final chip  = _slug(_asString(map['chipset']) ?? 'unknown');
    final sock  = _slug(_asString(map['socket']) ?? 'unknown');
    return 'mainboard-$brand-$name-$chip-$sock';
  }

  factory MainboardPart.fromMap(Map<String, dynamic> map) {
    final partId = _asString(map['partId']) ?? _asString(map['part_id']) ?? _genId(map);

    final memory  = _cast<Map<String, dynamic>>(map['memory']);
    final storage = _cast<Map<String, dynamic>>(map['storage']);
    final pcie    = _cast<Map<String, dynamic>>(map['pci_express']) ?? _cast<Map<String, dynamic>>(map['pciExpress']);

    final x16 = _asInt(pcie?['x16_slots'] ?? pcie?['x16Slots']) ?? 0;
    final x4  = _asInt(pcie?['x4_slots']  ?? pcie?['x4Slots'])  ?? 0;
    final x1  = _asInt(pcie?['x1_slots']  ?? pcie?['x1Slots'])  ?? 0;

    return MainboardPart(
      partId: partId,
      brand: _asString(map['brand']) ?? 'N/A',
      modelName: _asString(map['name'] ?? map['model'] ?? map['modelName']) ?? 'N/A',
      referencePrice: _asInt(map['price'] ?? map['reference_price']),
      imageUrl: _asString(map['image_url'] ?? map['imageUrl']),
      powerConsumptionW: _asInt(map['power_consumption_w'] ?? map['powerConsumptionW']),
      socket: _asString(map['socket']) ?? '',
      chipset: _asString(map['chipset']) ?? '',
      formFactor: _asString(map['form_factor_simple'] ?? map['form_factor'] ?? map['formFactor']) ?? '',
      memorySlots: _asInt(map['memory_slots'] ?? memory?['slots']) ?? 0,
      maxMemoryGb: _asInt(map['memory_max_capacity'] ?? memory?['max_capacity_gb'] ?? memory?['maxCapacityGb']) ?? 0,
      memoryType: _asString(map['memory_type'] ?? memory?['type']) ?? '',
      pcieSlots: _asInt(map['pcie_x16_slots']) ?? (x16 + x4 + x1),
      sataPorts: _asInt(map['sata_ports'] ?? storage?['sata3_ports'] ?? storage?['sata3Ports']) ?? 0,
      m2Slots: _asInt(map['m2_slots'] ?? storage?['m2_slots'] ?? storage?['m2Slots']) ?? 0,
    );
  }

  @override
  Map<String, dynamic> toMap() => {
    ...super.toMap(),
    'socket': socket,
    'chipset': chipset,
    'formFactor': formFactor,
    'memorySlots': memorySlots,
    'maxMemoryGb': maxMemoryGb,
    'memoryType': memoryType,
    'pcieSlots': pcieSlots,
    'sataPorts': sataPorts,
    'm2Slots': m2Slots,
  };
}

/// ==================== Generic(안전장치) ====================

class GenericPart extends Part {
  const GenericPart({
    required super.partId,
    required super.category,
    required super.brand,
    required super.modelName,
    super.referencePrice,
    super.imageUrl,
    super.powerConsumptionW,
    super.generation,
    super.codename,
    super.packaging,
  });

  static String _genId(Map<String, dynamic> map, PartCategory cat) {
    final brand = _slug(_asString(map['brand']) ?? 'unknown');
    final model = _slug(_asString(map['modelName'] ?? map['model'] ?? map['name']) ?? 'unknown');
    return '${cat.name}-$brand-$model-generic';
  }

  factory GenericPart.fromMap(Map<String, dynamic> map) {
    final cat = _parseCategory(map['category']);
    final existing = _asString(map['partId']) ?? _asString(map['part_id']) ?? _asString(map['objectID']);
    final partId = existing ?? _genId(map, cat);
    return GenericPart(
      partId: partId,
      category: cat,
      brand: _asString(map['brand']) ?? 'N/A',
      modelName: _asString(map['modelName'] ?? map['model'] ?? map['name']) ?? 'N/A',
      referencePrice: _asInt(map['reference_price'] ?? map['price'] ?? map['pricing']?['basePrice']),
      imageUrl: _asString(map['image_url'] ?? map['imageUrl']),
      powerConsumptionW: _asInt(map['power_consumption_w'] ?? map['powerConsumptionW']),
      generation: _asString(map['generation']),
      codename: _asString(map['codename']),
      packaging: _asString(map['packaging']),
    );
  }

  @override
  Map<String, dynamic> toMap() => super.toMap();
}
