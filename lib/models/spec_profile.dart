// lib/models/spec_profile.dart
import 'estimate_sample_model.dart'; // HardwareRecommendation 사용을 위해 import

class SpecProfile {
  final String? cpuSocket;
  final String? ramType;
  final String? motherboardFormFactor;
  final String? cpuPerformanceTier;
  final String? gpuPerformanceTier;
  final int? recommendedPsuWattage;
  final HardwareRecommendation? recommendationText; // UI 표시용 추천 텍스트

  SpecProfile({
    this.cpuSocket,
    this.ramType,
    this.motherboardFormFactor,
    this.cpuPerformanceTier,
    this.gpuPerformanceTier,
    this.recommendedPsuWattage,
    this.recommendationText, // 생성자에 추가
  });
}