import 'package:cloud_firestore/cloud_firestore.dart';

// ==================== 공용 유틸 ====================
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
String _ifaceToString({dynamic type, dynamic version, dynamic lanes}) {
  final t = _asString(type)?.trim() ?? '';
  final v = _asString(version)?.trim() ?? '';
  final l = (_asInt(lanes) != null) ? 'x${_asInt(lanes)}' : '';
  return [t, v, l].where((s) => s.isNotEmpty).join(' ');
}

// ==================== 카테고리 ====================
enum PartCategory { cpu, gpu, ssd, mainboard, ram, psu, cooler, pccase }
PartCategory _parseCategory(dynamic raw) {
  final s = (_asString(raw) ?? '').toLowerCase();
  if (s == 'motherboard' || s == 'mb') return PartCategory.mainboard;
  return PartCategory.values.firstWhere((e) => e.name == s, orElse: () => PartCategory.pccase);
}

// ==================== MemorySpec ====================
class MemorySpec {
  final String type;
  final int maxSpeedMhz;
  final int channels;

  const MemorySpec({ required this.type, required this.maxSpeedMhz, required this.channels });
  factory MemorySpec.fromMap(Map<String, dynamic>? map) {
    final m = map ?? const {};
    return MemorySpec(
      type: _asString(m['type']) ?? '',
      maxSpeedMhz: _asInt(m['maxSpeedMhz'] ?? m['max_speed_mhz']) ?? 0,
      channels: _asInt(m['channels']) ?? 0,
    );
  }
}

// ==================== 공통 Part 베이스 ====================
abstract class Part {
  final String partId;
  final PartCategory category;
  final String brand;
  final String modelName;
  final int? referencePrice;
  final String? imageUrl;
  final int? powerConsumptionW;

  const Part({
    required this.partId,
    required this.category,
    required this.brand,
    required this.modelName,
    this.referencePrice,
    this.imageUrl,
    this.powerConsumptionW,
  });

  factory Part.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>? ?? {});
    data.putIfAbsent('partId', () => data['part_id'] ?? doc.id);
    return Part.fromMap(data);
  }

  factory Part.fromMap(Map<String, dynamic> map) {
    final category = _parseCategory(map['category']);
    switch (category) {
      case PartCategory.cpu: return CpuPart.fromMap(map);
      case PartCategory.gpu: return GpuPart.fromMap(map);
      case PartCategory.mainboard: return MainboardPart.fromMap(map);
      default: return GenericPart.fromMap(map);
    }
  }
}

// ==================== CPU ====================
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
    final raw = _cast<Map<String, dynamic>>(map['raw']);
    return CpuPart(
      partId: _asString(map['partId']) ?? _asString(map['part_id']) ?? 'N/A',
      brand: _asString(map['brand']) ?? 'N/A',
      // 💥 최종 통합된 모델명 파싱 로직
      modelName: _asString(map['modelName']) ?? _asString(map['name']) ?? _asString(map['model']) ?? _asString(raw?['name']) ?? _asString(raw?['model']) ?? '',
      referencePrice: _asInt(map['referencePrice'] ?? map['reference_price']),
      imageUrl: _asString(map['imageUrl'] ?? map['image_url']),
      powerConsumptionW: _asInt(map['powerConsumptionW'] ?? map['power_consumption_w']),
      socket: _asString(map['socket']) ?? '',
      hasIntegratedGraphics: (map['hasIntegratedGraphics'] ?? map['has_integrated_graphics']) == true,
      cores: _asInt(map['cores']) ?? 0,
      threads: _asInt(map['threads']) ?? 0,
      baseClockGhz: _asDouble(map['baseClockGhz'] ?? map['base_clock_ghz']) ?? 0.0,
      boostClockGhz: _asDouble(map['boostClockGhz'] ?? map['boost_clock_ghz']) ?? 0.0,
      l3CacheMb: _asDouble(map['l3CacheMb'] ?? map['l3_cache_mb']) ?? 0.0,
      igpuName: _asString(map['igpuName'] ?? map['igpu_name']),
      igpuFreqMhz: _asInt(map['igpuFreqMhz'] ?? map['igpu_freq_mhz']),
      memory: MemorySpec.fromMap(_cast<Map<String, dynamic>>(map['memory'])),
      coolerIncluded: (map['coolerIncluded'] ?? map['cooler_included']) == true,
    );
  }
}

// ==================== GPU ====================
class GpuPart extends Part {
  final String chipset;
  final int memorySizeGb;
  final String memoryType;
  final String? interfaceType;
  final int? boostClockMhz;
  final int? cudaCores;

  const GpuPart({
    required super.partId,
    required super.brand,
    required super.modelName,
    super.referencePrice,
    super.imageUrl,
    super.powerConsumptionW,
    required this.chipset,
    required this.memorySizeGb,
    required this.memoryType,
    this.interfaceType,
    this.boostClockMhz,
    this.cudaCores,
  }) : super(category: PartCategory.gpu);

  factory GpuPart.fromMap(Map<String, dynamic> map) {
    final raw = _cast<Map<String, dynamic>>(map['raw']);
    final memory = _cast<Map<String, dynamic>>(map['memory']);
    final chipsetMap = _cast<Map<String, dynamic>>(map['chipset']);
    final iface = _cast<Map<String, dynamic>>(map['interface']);
    final clocks = _cast<Map<String, dynamic>>(map['clockSpeeds'] ?? map['clock_speeds']);
    final power = _cast<Map<String, dynamic>>(map['power']);
    return GpuPart(
      partId: _asString(map['partId']) ?? _asString(map['part_id']) ?? 'N/A',
      brand: _asString(map['brand']) ?? 'N/A',
      // 💥 최종 통합된 모델명 파싱 로직
      modelName: _asString(map['modelName']) ?? _asString(map['name']) ?? _asString(map['model']) ?? _asString(raw?['name']) ?? _asString(raw?['model']) ?? '',
      referencePrice: _asInt(map['referencePrice'] ?? map['reference_price']),
      imageUrl: _asString(map['imageUrl'] ?? map['image_url']),
      powerConsumptionW: _asInt(power?['recommendedPsuWatt'] ?? power?['recommended_psu_watt']),
      chipset: _asString(chipsetMap?['model']) ?? '',
      memorySizeGb: _asInt(memory?['sizeGb'] ?? memory?['size_gb']) ?? 0,
      memoryType: _asString(memory?['type']) ?? '',
      interfaceType: _ifaceToString(type: iface?['type'], version: iface?['version'], lanes: iface?['lanes']),
      boostClockMhz: _asInt(clocks?['boostMhz'] ?? clocks?['boost_mhz']),
      cudaCores: _asInt(chipsetMap?['cudaCores'] ?? chipsetMap?['cuda_cores']),
    );
  }
}

// ==================== 메인보드 ====================
class MainboardPart extends Part {
  final String socket;
  final String chipset;
  final String formFactor;
  final String memoryType;
  final int memorySlots;
  final int maxMemoryGb;
  final int sataPorts;
  final int m2Slots;

  const MainboardPart({
    required super.partId,
    required super.brand,
    required super.modelName,
    super.referencePrice,
    super.imageUrl,
    required this.socket,
    required this.chipset,
    required this.formFactor,
    required this.memoryType,
    required this.memorySlots,
    required this.maxMemoryGb,
    required this.sataPorts,
    required this.m2Slots,
  }) : super(category: PartCategory.mainboard);

  factory MainboardPart.fromMap(Map<String, dynamic> map) {
    final raw = _cast<Map<String, dynamic>>(map['raw']);
    final memory = _cast<Map<String, dynamic>>(map['memory']);
    final storage = _cast<Map<String, dynamic>>(map['storage']);
    return MainboardPart(
      partId: _asString(map['partId']) ?? _asString(map['part_id']) ?? 'N/A',
      brand: _asString(map['brand']) ?? 'N/A',
      // 💥 최종 통합된 모델명 파싱 로직
      modelName: _asString(map['modelName']) ?? _asString(map['name']) ?? _asString(map['model']) ?? _asString(raw?['name']) ?? _asString(raw?['model']) ?? '',
      referencePrice: _asInt(map['referencePrice'] ?? map['reference_price']),
      imageUrl: _asString(map['imageUrl'] ?? map['image_url']),
      socket: _asString(map['socket']) ?? '',
      chipset: _asString(map['chipset']) ?? '',
      formFactor: _asString(map['formFactor'] ?? map['form_factor']) ?? '',
      memoryType: _asString(memory?['type']) ?? '',
      memorySlots: _asInt(memory?['slots']) ?? 0,
      maxMemoryGb: _asInt(memory?['maxCapacityGb'] ?? memory?['max_capacity_gb']) ?? 0,
      sataPorts: _asInt(storage?['sata3Ports'] ?? storage?['sata3_ports']) ?? 0,
      m2Slots: _asInt(storage?['m2Slots'] ?? storage?['m2_slots']) ?? 0,
    );
  }
}

// ==================== Generic 모델 ====================
class GenericPart extends Part {
  const GenericPart({
    required super.partId,
    required super.category,
    required super.brand,
    required super.modelName,
    super.referencePrice,
    super.imageUrl,
    super.powerConsumptionW,
  });

  factory GenericPart.fromMap(Map<String, dynamic> map) {
    final raw = _cast<Map<String, dynamic>>(map['raw']);
    return GenericPart(
      partId: _asString(map['partId']) ?? _asString(map['part_id']) ?? 'N/A',
      category: _parseCategory(map['category']),
      brand: _asString(map['brand']) ?? 'N/A',
      // 💥 최종 통합된 모델명 파싱 로직
      modelName: _asString(map['modelName']) ?? _asString(map['name']) ?? _asString(map['model']) ?? _asString(raw?['name']) ?? _asString(raw?['model']) ?? '',
      referencePrice: _asInt(map['referencePrice'] ?? map['reference_price']),
      imageUrl: _asString(map['imageUrl'] ?? map['image_url']),
      powerConsumptionW: _asInt(map['powerConsumptionW'] ?? map['power_consumption_w']),
    );
  }
}