// lib/services/recommendation_service.dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/spec_profile.dart';
import '../models/part_model.dart';
import '../models/estimate_sample_model.dart';

class RecommendationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  EstimateSamples? _estimateSamples;

  static const Map<String, Map<String, dynamic>> _questionData = { 'Q1': { 'text': '컴퓨터의 주된 용도는?', 'options': {'① 게임': 'G', '② 창작작업': 'C', '③ 사무·개발': 'O'},}, 'Q2': { 'text': '예산 범위 (만원 단위)', 'options': 'BUDGET', }, 'Q3': { 'text': '필요한 SSD 용량 (GB)', 'options': {'① 500': 500, '② 1000': 1000, '③ 2000': 2000, '④ 그 이상': 9999},}, 'Q4G': { 'text': '즐기실 게임 번호 선택 (최대 3개)', 'options': 'GAMES', 'hint': '1~154번 사이의 게임 번호를 입력하세요',}, 'Q5G': { 'text': '현재 모니터 해상도', 'options': {'① FHD': 'FHD', '② QHD': 'QHD', '③ 4K': '4K'},}, 'Q6G': { 'text': '원하는 평균 FPS', 'options': {'① 60': 60, '② 100': 100, '③ 120': 120, '④ 144': 144, '⑤ 165': 165, '⑥ 240': 240},}, 'Q7G': { 'text': '선호하는 그래픽 품질', 'options': {'① 낮음': '낮음', '② 보통': '보통', '③ 높음': '높음', '④ 최고': '최고', '⑤ 레이트레이싱': '레이트레이싱'},}, 'Q4C': { 'text': '주로 사용하는 소프트웨어', 'options': {'① 프리미어': '프리미어', '② 블렌더': '블렌더', '③ 포토샵/라이트룸': '포토샵/라이트룸', '④ AE': 'AE', '⑤ C4D': 'C4D', '⑥ 기타': '기타'},}, 'Q5C': { 'text': '작업 영상/이미지 해상도', 'options': {'① FHD': 'FHD', '② QHD': 'QHD', '③ 4K': '4K', '④ 8K': '8K'},}, 'Q6C': { 'text': '프로젝트 규모', 'options': {'① 개인': '개인', '② 소규모': '소규모', '③ 대규모': '대규모', '④ 스튜디오급': '스튜디오급'},}, 'Q7C': { 'text': '렌더링 빈도', 'options': {'① 가끔': '가끔', '② 자주': '자주', '③ 실시간': '실시간'},}, 'Q4O': { 'text': '주된 업무', 'options': {'① 문서': '문서', '② 개발/코딩': '개발/코딩', '③ 웹서핑/이메일': '웹서핑/이메일', '④ 데이터분석': '데이터분석', '⑤ 기타': '기타'},}, 'Q5O': { 'text': '동시에 실행할 프로그램 수', 'options': {'① 5개 미만': '5개 미만', '② 5~10개': '5~10개', '③ 10개 이상': '10개 이상'},}, 'Q6O': { 'text': '사용할 모니터 개수', 'options': {'① 1개': '1개', '② 2개': '2개', '③ 3개 이상': '3개 이상'},}, 'Q7O': { 'text': '저장할 데이터 규모', 'options': {'① 100GB 미만': '100GB 미만', '② 1TB 미만': '1TB 미만', '③ 1TB 이상': '1TB 이상'},},};

  Future<void> _loadEstimateData() async {
    if (_estimateSamples == null) {
      final jsonString = await rootBundle.loadString('assets/data/estimate_full.json');
      _estimateSamples = EstimateSamples.fromJson(json.decode(jsonString));
    }
  }

  Future<SpecProfile> getProfileForUserAnswers(Map<String, dynamic> userAnswers) async {
    await _loadEstimateData();

    final unrealisticReason = _checkUnrealisticCombinations(userAnswers);
    if (unrealisticReason != null) {
      throw Exception(unrealisticReason);
    }

    final bestMatchSample = _findBestMatch(_estimateSamples!, userAnswers);

    if (bestMatchSample == null) {
      throw Exception('추천 견적을 찾지 못했습니다.');
    }

    final recommendations = bestMatchSample.hardwareRecommendations.first;

    final cpuFuture = _getPartByName(recommendations.cpu, PartCategory.cpu);
    final mbFuture = _getPartByName(recommendations.mainboard, PartCategory.mainboard);
    final gpuFuture = _getPartByName(recommendations.gpu, PartCategory.gpu);

    final parts = await Future.wait([cpuFuture, mbFuture, gpuFuture]);
    final cpuPart = parts[0] as CpuPart?;
    final mbPart = parts[1] as MainboardPart?;
    final gpuPart = parts[2] as GpuPart?;

    return SpecProfile(
      cpuSocket: cpuPart?.socket,
      ramType: mbPart?.memoryType ?? cpuPart?.memory.type,
      motherboardFormFactor: mbPart?.formFactor,
      recommendedPsuWattage: gpuPart?.powerConsumptionW,
      recommendationText: recommendations,
    );
  }

  Future<Part?> _getPartByName(String? modelName, PartCategory category) async {
    if (modelName == null || modelName.isEmpty) return null;

    final querySnapshot = await _firestore.collection('parts').where('category', isEqualTo: category.name).where('modelName', isEqualTo: modelName).limit(1).get();

    if (querySnapshot.docs.isNotEmpty) {
      return Part.fromFirestore(querySnapshot.docs.first);
    }
    print('Warning: Part not found in DB for modelName: $modelName');
    return null;
  }

  String? _checkUnrealisticCombinations(Map<String, dynamic> answers) {
    final budgetParts = (answers['Q2'] as String? ?? '0 ~ 0').split(' ~ ');
    final maxBudget = int.tryParse(budgetParts[1]) ?? 0;
    if (answers['Q3'] == 500 && (answers['Q5C'] == '4K' || answers['Q5C'] == '8K' || answers['Q6C'] == '대규모' || answers['Q6C'] == '스튜디오급')) return '고해상도 미디어 파일은 용량이 매우 크므로 500GB는 심각하게 부족하며, 최소 1TB 이상(권장 2TB)이 필요합니다.';
    if (answers['Q5C'] == '4K' && (answers['Q3'] == 500 || answers['Q6C'] == '대규모' || answers['Q6C'] == '스튜디오급')) return '4K 작업은 시스템 자원을 많이 소모하며, 특히 SSD 용량과 프로젝트 규모가 클수록 메모리/CPU/GPU 성능이 매우 중요합니다.';
    if (answers['Q5C'] == '8K') return '8K는 현존하는 일반 PC 환경에서 최고 사양을 요구합니다. 제공된 모든 견적으로는 원활한 8K 작업이 사실상 불가능합니다.';
    if (answers['Q6C'] == '대규모' && (answers['Q3'] == 500 || answers['Q3'] == 1000 || answers['Q5C'] == '4K' || answers['Q5C'] == '8K')) return '대규모 프로젝트는 수백 GB의 용량과 엄청난 시스템 자원을 필요로 합니다. 최소 2TB SSD 및 고성능 CPU/GPU/RAM(64GB 이상)이 필수입니다.';
    if (answers['Q6C'] == '스튜디오급') return '\'스튜디오급\' 작업은 전문적인 워크스테이션 수준의 사양(고성능 CPU/GPU, 2TB 이상 SSD, 128GB+ RAM)을 의미하며, 제공된 모든 견적 사양으로는 적합하지 않습니다.';
    if (answers['Q7C'] == '실시간' && (answers['Q5C'] == '4K' || answers['Q5C'] == '8K' || answers['Q6C'] == '대규모' || answers['Q6C'] == '스튜디오급')) return '실시간 렌더링은 GPU의 VRAM과 CUDA/Tensor 코어 성능이 매우 중요하며, 제공된 견적 사양으로는 4K 이상에서 불가능합니다.';
    if (answers['Q5O'] == '10개 이상' && (answers['Q3'] == 500 || answers['Q3'] == 1000 || answers['Q7O'] == '1TB 미만')) return '10개 이상의 고사양 프로그램을 동시에 실행하려면 최소 32GB RAM(권장 64GB)과 2TB 이상의 고속 SSD가 필요합니다.';
    if (answers['Q7O'] == '1TB 이상' && answers['Q3'] == 500) return '저장 공간(Q7O)이 필요한 SSD 용량(Q3)보다 커서, 주 저장 장치로는 부족합니다. 이는 외부 저장소를 필수적으로 가정해야만 가능한 조합입니다.';
    if (maxBudget < 50 && (answers['Q4O'] == '데이터분석' || answers['Q5O'] == '10개 이상' || answers['Q7O'] == '1TB 이상')) return '이 예산은 문서/웹서핑(Q4O: ①, ③)용입니다. 데이터 분석(LLM)은 최소 390만원 견적(64GB RAM, RTX 5080)이 필요하며, 10개 이상 실행에는 고용량 RAM이 필수입니다.';
    if (maxBudget < 100 && (answers['Q4O'] == '데이터분석' || answers['Q5O'] == '10개 이상' || answers['Q7O'] == '1TB 이상')) return '이 예산은 개발/코딩 입문 정도에 적합합니다. 데이터 분석(LLM)은 불가능하며, 10개 이상 프로그램 실행에 필요한 32GB~64GB RAM 구성이 어렵습니다.';
    if (maxBudget < 250 && answers['Q4O'] == '데이터분석') return 'LLM 딥러닝에 필요한 고성능 GPU(RTX 5080/5090)와 64GB 이상의 RAM 구성은 최소 390만원 이상이 필요합니다.';
    if (maxBudget < 400 && answers['Q4O'] == '데이터분석' && answers['Q5O'] == '10개 이상' && answers['Q7O'] == '1TB 이상') return 'LLM개발용(390만원) 견적의 사양입니다. 이 사양은 고성능이지만, 최고 사양 AI 개발(660만원 견적의 RTX 5090 급)까지 커버하기는 어렵습니다.';
    return null;
  }

  Sample? _findBestMatch(EstimateSamples samples, Map<String, dynamic> userAnswers) {
    int bestScore = -1;
    Sample? bestMatch;
    double minAbsBudgetDiff = double.infinity;
    Sample? closestBudgetMatch;
    final budgetParts = (userAnswers['Q2'] as String).split(' ~ ');
    final userMinBudget = int.tryParse(budgetParts[0]) ?? 0;
    final userMaxBudget = int.tryParse(budgetParts[1]) ?? 0;
    final userAvgBudget = (userMinBudget + userMaxBudget) / 2.0;
    for (final sample in samples.samples) {
      int currentScore = 0;
      if (sample.budget != null) {
        final sampleMin = sample.budget!.min;
        final sampleMax = sample.budget!.max;
        final sampleAvg = (sampleMin + sampleMax) / 2.0;
        if (userMinBudget <= sampleMax && userMaxBudget >= sampleMin) {
          currentScore += 20;
          if (userAvgBudget >= sampleMin && userAvgBudget <= sampleMax) {
            currentScore += 15;
          }
        }
        final absDiff = (userAvgBudget - sampleAvg).abs();
        if (absDiff < minAbsBudgetDiff) {
          minAbsBudgetDiff = absDiff;
          closestBudgetMatch = sample;
        }
      }
      final userSsd = userAnswers['Q3'] as int;
      final sampleSsd = int.tryParse(sample.ssd ?? '0') ?? 0;
      if (sampleSsd >= userSsd) {
        currentScore += 10;
      }
      final usage = userAnswers['Q1'];
      if (sample.task != null) {
        final task = sample.task!;
        MapEntry<String, String>? mainUseEntry;
        try {
          mainUseEntry = ( _questionData['Q1']!['options'] as Map<String, String>).entries.firstWhere((e) => e.value == usage);
        } catch (e) { mainUseEntry = null; }
        String mainUseText = '';
        if (mainUseEntry != null && mainUseEntry.key.length > 2) {
          mainUseText = mainUseEntry.key.substring(2).trim();
        }
        bool mainUseMatches = task.mainUse == null || (mainUseText.isNotEmpty && task.mainUse!.contains(mainUseText));
        if(mainUseMatches) {
          currentScore += 10;
          switch (usage) {
            case 'C':
              if (task.software != null && userAnswers['Q4C'] != null && task.software!.contains(userAnswers['Q4C'])) currentScore += 20;
              if (task.resolution != null && userAnswers['Q5C'] != null && task.resolution!.contains(userAnswers['Q5C'])) currentScore += 15;
              if (task.scale != null && userAnswers['Q6C'] != null && task.scale!.contains(userAnswers['Q6C'])) currentScore += 10;
              if (task.frequency != null && userAnswers['Q7C'] != null && task.frequency!.contains(userAnswers['Q7C'])) currentScore += 10;
              break;
            case 'O':
              if (task.work != null && userAnswers['Q4O'] != null && task.work!.contains(userAnswers['Q4O'])) currentScore += 20;
              if (task.progs != null && userAnswers['Q5O'] != null && task.progs!.contains(userAnswers['Q5O'])) currentScore += 10;
              if (task.monitors != null && userAnswers['Q6O'] != null && task.monitors!.contains(userAnswers['Q6O'])) currentScore += 10;
              if (task.dataSize != null && userAnswers['Q7O'] != null && task.dataSize!.contains(userAnswers['Q7O'])) currentScore += 10;
              break;
            case 'G':
              if (userAnswers['Q4G'] != null && task.gameIds != null) {
                final userGames = (userAnswers['Q4G'] as String).split(', ');
                int matchCount = 0;
                for (var game in userGames) { if (task.gameIds!.contains(game)) matchCount++; }
                currentScore += matchCount * 10;
              }
              if (task.resolution != null && userAnswers['Q5G'] != null && task.resolution!.contains(userAnswers['Q5G'])) currentScore += 15;
              break;
          }
        }
      }
      if (currentScore > bestScore) {
        bestScore = currentScore;
        bestMatch = sample;
      }
    }
    if (bestScore < 20 && closestBudgetMatch != null) bestMatch = closestBudgetMatch;
    if (bestMatch == null && closestBudgetMatch != null) bestMatch = closestBudgetMatch;
    return bestMatch;
  }
}