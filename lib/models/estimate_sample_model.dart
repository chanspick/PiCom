import 'package:flutter/foundation.dart';

// Represents the entire JSON structure
class EstimateSamples {
  final List<Sample> samples;

  EstimateSamples({required this.samples});

  factory EstimateSamples.fromJson(Map<String, dynamic> json) {
    return EstimateSamples(
      samples: (json['samples'] as List<dynamic>)
          .map((e) => Sample.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// Represents a single recommendation sample
class Sample {
  final String? matchKey;
  final Budget? budget;
  final String? ssd;
  final Task? task;
  final List<HardwareRecommendation> hardwareRecommendations;

  Sample({
    this.matchKey,
    this.budget,
    this.ssd,
    this.task,
    required this.hardwareRecommendations,
  });

  factory Sample.fromJson(Map<String, dynamic> json) {
    return Sample(
      matchKey: json['match_key'] as String?,
      budget: json['budget'] != null ? Budget.fromJson(json['budget'] as Map<String, dynamic>) : null,
      ssd: json['ssd'] as String?,
      task: json['task'] != null ? Task.fromJson(json['task'] as Map<String, dynamic>) : null,
      hardwareRecommendations: (json['hardware_recommendations'] as List<dynamic>)
          .map((e) => HardwareRecommendation.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// Represents the budget range
class Budget {
  final int min;
  final int max;

  Budget({required this.min, required this.max});

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      min: json['min'] as int,
      max: json['max'] as int,
    );
  }
}

// Represents the task details for a sample
class Task {
  final String? mainUse;
  final List<String>? gameIds;
  final String? software;
  final String? resolution;
  final String? scale;
  final String? frequency;
  final String? work;
  final String? progs;
  final String? monitors;
  final String? dataSize;

  Task({
    this.mainUse,
    this.gameIds,
    this.software,
    this.resolution,
    this.scale,
    this.frequency,
    this.work,
    this.progs,
    this.monitors,
    this.dataSize,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      mainUse: json['main_use'] as String?,
      gameIds: json['game_ids'] != null ? List<String>.from(json['game_ids']) : null,
      software: json['software'] as String?,
      resolution: json['resolution'] as String?,
      scale: json['scale'] as String?,
      frequency: json['frequency'] as String?,
      work: json['work'] as String?,
      progs: json['progs'] as String?,
      monitors: json['monitors'] as String?,
      dataSize: json['data_size'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'main_use': mainUse,
      'game_ids': gameIds,
      'software': software,
      'resolution': resolution,
      'scale': scale,
      'frequency': frequency,
      'work': work,
      'progs': progs,
      'monitors': monitors,
      'data_size': dataSize,
    };
  }
}

// Represents the recommended hardware components
class HardwareRecommendation {
  final String? cpu;
  final String? mainboard;
  final String? memory;
  final String? gpu;
  final String? ssd;
  final String? psu;
  final String? cpuCooler;
  final String? pcCase;

  HardwareRecommendation({
    this.cpu,
    this.mainboard,
    this.memory,
    this.gpu,
    this.ssd,
    this.psu,
    this.cpuCooler,
    this.pcCase,
  });

  factory HardwareRecommendation.fromJson(Map<String, dynamic> json) {
    return HardwareRecommendation(
      cpu: json['cpu'] as String?,
      mainboard: json['mainboard'] as String?,
      memory: json['memory'] as String?,
      gpu: json['gpu'] as String?,
      ssd: json['ssd'] as String?,
      psu: json['psu'] as String?,
      cpuCooler: json['cpu_cooler'] as String?,
      pcCase: json['case'] as String?,
    );
  }
}

