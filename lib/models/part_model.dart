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
      case PartCategory.gpu:
        return GpuPart.fromMap(map);
      case PartCategory.mainboard:
        return MainboardPart.fromMap(map);
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

    // 5.1. Part를 상속받는 GpuPart 클래스
    class GpuPart extends Part {
      final String chipset;
      final int memorySizeGb;
      final String memoryType;
      final String interfaceType; // PCIe 4.0 x16
      final int? boostClockMhz;
      final int? cudaCores; // 또는 Stream Processors
      final int? tdpW; // Thermal Design Power

      GpuPart({
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
        required this.interfaceType,
        this.boostClockMhz,
        this.cudaCores,
        this.tdpW,
      }) : super(category: PartCategory.gpu);

      factory GpuPart.fromMap(Map<String, dynamic> map) {
        final specs = map['specs'] as Map<String, dynamic>?;
        final memory = specs?['memory'] as Map<String, dynamic>?;
        final interface = specs?['interface'] as Map<String, dynamic>?;
        final performance = specs?['performance'] as Map<String, dynamic>?;

        return GpuPart(
          partId: map['partId'] ?? '',
          brand: map['brand'] ?? '',
          modelName: map['model'] ?? 'N/A',
          referencePrice: (map['pricing']?['basePrice'] as num?)?.toInt(),
          imageUrl: map['image_url'], // JSON에 image_url 필드가 없으므로 null 가능
          powerConsumptionW: performance?['recommendedPsuWatt']?.toInt(), // recommendedPsuWatt를 powerConsumptionW로 사용
          generation: map['generation'],
          codename: map['codename'],
          packaging: map['packaging'],
          chipset: specs?['chipsetModel'] ?? '',
          memorySizeGb: memory?['sizeGb']?.toInt() ?? 0,
          memoryType: memory?['type'] ?? '',
          interfaceType: '${interface?['type'] ?? ''} ${interface?['version'] ?? ''} x${interface?['lanes'] ?? ''}'.trim(),
          boostClockMhz: specs?['boostClockMhz']?.toInt(),
          cudaCores: performance?['cudaCores']?.toInt(),
          tdpW: specs?['tdpW']?.toInt(), // JSON에 tdpW 필드가 없으므로 null 가능
        );
      }

      Map<String, dynamic> toMap() {
        return {
          ...super.toMap(), // Include fields from the base Part class
          'category': PartCategory.gpu.name,
          'chipset': chipset,
          'memory_size_gb': memorySizeGb,
          'memory_type': memoryType,
          'interface_type': interfaceType,
          'boost_clock_mhz': boostClockMhz,
          'cuda_cores': cudaCores,
          'tdp_w': tdpW,
        };
      }
    }

    // 5.2. Part를 상속받는 MainboardPart 클래스
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

      MainboardPart({
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

      factory MainboardPart.fromMap(Map<String, dynamic> map) {
        final specs = map['specs'] as Map<String, dynamic>?;
        final memory = specs?['memory'] as Map<String, dynamic>?;
        final storage = specs?['storage'] as Map<String, dynamic>?;
        final pciExpress = specs?['pciExpress'] as Map<String, dynamic>?;

        return MainboardPart(
          partId: map['partId'] ?? '',
          brand: map['brand'] ?? '',
          modelName: map['name'] ?? map['model'] ?? 'N/A',
          referencePrice: (map['pricing']?['basePrice'] as num?)?.toInt(),
          imageUrl: map['image_url'],
          powerConsumptionW: map['power_consumption_w']?.toInt(),
          generation: map['generation'],
          codename: map['codename'],
          packaging: map['packaging'],
          socket: specs?['socket'] ?? '',
          chipset: specs?['chipset'] ?? '',
          formFactor: specs?['formFactor'] ?? '',
          memorySlots: memory?['slots']?.toInt() ?? 0,
          maxMemoryGb: memory?['maxCapacityGb']?.toInt() ?? 0,
          memoryType: memory?['type'] ?? '',
          pcieSlots: (pciExpress?['x16Slots']?.toInt() ?? 0) + (pciExpress?['x4Slots']?.toInt() ?? 0) + (pciExpress?['x1Slots']?.toInt() ?? 0),
          sataPorts: storage?['sata3Ports']?.toInt() ?? 0,
          m2Slots: storage?['m2Slots']?.toInt() ?? 0,
        );
      }

      Map<String, dynamic> toMap() {
        return {
          ...super.toMap(), // Include fields from the base Part class
          'category': PartCategory.mainboard.name,
          'socket': socket,
          'chipset': chipset,
          'form_factor': formFactor,
          'memory_slots': memorySlots,
          'max_memory_gb': maxMemoryGb,
          'memory_type': memoryType,
          'pcie_slots': pcieSlots,
          'sata_ports': sataPorts,
          'm2_slots': m2Slots,
        };
      }
    }

    // 6. 상세 정보가 없는 부품을 위한 GenericPart 클래스 (안전장치)
    class GenericPart extends Part {  GenericPart({
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
