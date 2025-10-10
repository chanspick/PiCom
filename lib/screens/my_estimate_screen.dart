import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:picom/models/estimate_sample_model.dart';

class MyEstimateScreen extends StatefulWidget {
  const MyEstimateScreen({super.key});

  @override
  State<MyEstimateScreen> createState() => _MyEstimateScreenState();
}

class _MyEstimateScreenState extends State<MyEstimateScreen> {
  // ---------------------------------------------------------------------------
  // QUESTION DATA
  // ---------------------------------------------------------------------------
  static const Map<String, Map<String, dynamic>> _questionData = {
    'Q1': {
      'text': '컴퓨터의 주된 용도는?',
      'options': {'① 게임': 'G', '② 창작작업': 'C', '③ 사무·개발': 'O'},
    },
    'Q2': {
      'text': '예산 범위 (만원 단위)',
      'options': 'BUDGET', // Special case for budget input
    },
    'Q3': {
      'text': '필요한 SSD 용량 (GB)',
      'options': {'① 500': 500, '② 1000': 1000, '③ 2000': 2000, '④ 그 이상': 9999},
    },
    // --- Game Branch ---
    'Q4G': {
      'text': '즐기실 게임 번호 선택 (최대 3개)',
      'options': 'GAMES', // Special case for game input
      'hint': '1~154번 사이의 게임 번호를 입력하세요',
    },
    'Q5G': {
      'text': '현재 모니터 해상도',
      'options': {'① FHD': 'FHD', '② QHD': 'QHD', '③ 4K': '4K'},
    },
    'Q6G': {
      'text': '원하는 평균 FPS',
      'options': {'① 60': 60, '② 100': 100, '③ 120': 120, '④ 144': 144, '⑤ 165': 165, '⑥ 240': 240},
    },
    'Q7G': {
      'text': '선호하는 그래픽 품질',
      'options': {'① 낮음': '낮음', '② 보통': '보통', '③ 높음': '높음', '④ 최고': '최고', '⑤ 레이트레이싱': '레이트레이싱'},
    },
    // --- Creative Branch ---
    'Q4C': {
      'text': '주로 사용하는 소프트웨어',
      'options': {'① 프리미어': '프리미어', '② 블렌더': '블렌더', '③ 포토샵/라이트룸': '포토샵/라이트룸', '④ AE': 'AE', '⑤ C4D': 'C4D', '⑥ 기타': '기타'},
    },
    'Q5C': {
      'text': '작업 영상/이미지 해상도',
      'options': {'① FHD': 'FHD', '② QHD': 'QHD', '③ 4K': '4K', '④ 8K': '8K'},
    },
    'Q6C': {
      'text': '프로젝트 규모',
      'options': {'① 개인': '개인', '② 소규모': '소규모', '③ 대규모': '대규모', '④ 스튜디오급': '스튜디오급'},
    },
    'Q7C': {
      'text': '렌더링 빈도',
      'options': {'① 가끔': '가끔', '② 자주': '자주', '③ 실시간': '실시간'},
    },
    // --- Office Branch ---
    'Q4O': {
      'text': '주된 업무',
      'options': {'① 문서': '문서', '② 개발/코딩': '개발/코딩', '③ 웹서핑/이메일': '웹서핑/이메일', '④ 데이터분석': '데이터분석', '⑤ 기타': '기타'},
    },
    'Q5O': {
      'text': '동시에 실행할 프로그램 수',
      'options': {'① 5개 미만': '5개 미만', '② 5~10개': '5~10개', '③ 10개 이상': '10개 이상'},
    },
    'Q6O': {
      'text': '사용할 모니터 개수',
      'options': {'① 1개': '1개', '② 2개': '2개', '③ 3개 이상': '3개 이상'},
    },
    'Q7O': {
      'text': '저장할 데이터 규모',
      'options': {'① 100GB 미만': '100GB 미만', '② 1TB 미만': '1TB 미만', '③ 1TB 이상': '1TB 이상'},
    },
  };

  // ---------------------------------------------------------------------------
  // STATE MANAGEMENT
  // ---------------------------------------------------------------------------
  final List<String> _history = ['Q1'];
  final Map<String, dynamic> _answers = {};
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _minBudgetController = TextEditingController();
  final TextEditingController _maxBudgetController = TextEditingController();
  final TextEditingController _game1Controller = TextEditingController();
  final TextEditingController _game2Controller = TextEditingController();
  final TextEditingController _game3Controller = TextEditingController();

  HardwareRecommendation? _recommendation;
  bool _isLoading = false;
  String? _error;

  String get _currentQCode => _history.last;
  bool get _isFinished => _currentQCode == 'Q_FINISH';

  @override
  void dispose() {
    _textController.dispose();
    _minBudgetController.dispose();
    _maxBudgetController.dispose();
    _game1Controller.dispose();
    _game2Controller.dispose();
    _game3Controller.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // NAVIGATION LOGIC
  // ---------------------------------------------------------------------------
  String _getNextQCode() {
    switch (_currentQCode) {
      case 'Q1': return 'Q2';
      case 'Q2': return 'Q3';
      case 'Q3':
        final usage = _answers['Q1'];
        return 'Q4$usage'; // Q4G, Q4C, or Q4O
      case 'Q4G': return 'Q5G';
      case 'Q5G': return 'Q6G';
      case 'Q6G': return 'Q7G';
      case 'Q4C': return 'Q5C';
      case 'Q5C': return 'Q6C';
      case 'Q6C': return 'Q7C';
      case 'Q4O': return 'Q5O';
      case 'Q5O': return 'Q6O';
      case 'Q6O': return 'Q7O';
      default: return 'Q_FINISH';
    }
  }

  void _onNext() {
    final currentQuestion = _questionData[_currentQCode]!;
    dynamic answer;

    if (_currentQCode == 'Q2') {
      final min = _minBudgetController.text.trim();
      final max = _maxBudgetController.text.trim();
      if (min.isEmpty || max.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('최소값과 최대값을 모두 입력해주세요.')));
        return;
      }
      final minVal = int.tryParse(min) ?? 0;
      final maxVal = int.tryParse(max) ?? 0;
      if (minVal > maxVal) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('최소값은 최대값보다 클 수 없습니다.')));
        return;
      }
      answer = '$min ~ $max';
    } else if (_currentQCode == 'Q4G') {
      final games = [
        _game1Controller.text.trim(),
        _game2Controller.text.trim(),
        _game3Controller.text.trim(),
      ].where((g) => g.isNotEmpty).toList();
      if (games.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('하나 이상의 게임 번호를 입력해주세요.')));
        return;
      }
      answer = games.join(', ');
    } else if (currentQuestion['options'] == 'N/A') {
      if (_textController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('답변을 입력해주세요.')));
        return;
      }
      answer = _textController.text.trim();
    } else {
      if (!_answers.containsKey(_currentQCode)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('답변을 선택해주세요.')));
        return;
      }
      answer = _answers[_currentQCode];
    }

    setState(() {
      _answers[_currentQCode] = answer;
      _textController.clear();
      final nextQ = _getNextQCode();
      _history.add(nextQ);
      if (nextQ == 'Q_FINISH') {
        _processResults();
      }
    });
  }

  void _onBack() {
    if (_history.length > 1) {
      setState(() {
        _recommendation = null;
        _error = null;
        final lastQ = _history.removeLast();
        _answers.remove(lastQ);
        
        _textController.clear();
        _minBudgetController.clear();
        _maxBudgetController.clear();
        _game1Controller.clear();
        _game2Controller.clear();
        _game3Controller.clear();

        final prevQ = _questionData[_currentQCode]!;
        final prevAnswer = _answers[_currentQCode];

        if (prevAnswer != null) {
          if (_currentQCode == 'Q2') {
            final parts = prevAnswer.toString().split(' ~ ');
            if (parts.length == 2) {
              _minBudgetController.text = parts[0];
              _maxBudgetController.text = parts[1];
            }
          } else if (_currentQCode == 'Q4G') {
            final games = prevAnswer.toString().split(', ');
            if (games.isNotEmpty) _game1Controller.text = games[0];
            if (games.length > 1) _game2Controller.text = games[1];
            if (games.length > 2) _game3Controller.text = games[2];
          } else if (prevQ['options'] == 'N/A') {
            _textController.text = prevAnswer;
          }
        }
      });
    }
  }
  
  void _onRestart() {
    setState(() {
      _history.clear();
      _history.add('Q1');
      _answers.clear();
      _textController.clear();
      _minBudgetController.clear();
      _maxBudgetController.clear();
      _game1Controller.clear();
      _game2Controller.clear();
      _game3Controller.clear();
      _recommendation = null;
      _isLoading = false;
      _error = null;
    });
  }

  // ---------------------------------------------------------------------------
  // DATA PROCESSING
  // ---------------------------------------------------------------------------
  Future<void> _processResults() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _recommendation = null;
    });

    // First, check for unrealistic combinations.
    final unrealisticCombinationReason = _checkUnrealisticCombinations(_answers);
    if (unrealisticCombinationReason != null) {
      setState(() {
        _error = unrealisticCombinationReason;
        _isLoading = false;
      });
      return;
    }

    try {
      final jsonString = await rootBundle.loadString('assets/data/estimate_full.json');
      final jsonData = json.decode(jsonString);
      final estimateSamples = EstimateSamples.fromJson(jsonData);
      
      final bestMatch = _findBestMatch(estimateSamples, _answers);

      setState(() {
        _recommendation = bestMatch;
      });

    } catch (e, s) {
      print('Error processing results: $e\n$s');
      setState(() {
        _error = '견적 추천 중 오류가 발생했습니다:\n$e';
      });
    }
    finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String? _checkUnrealisticCombinations(Map<String, dynamic> answers) {
    // Helper to parse budget
    final budgetParts = (answers['Q2'] as String? ?? '0 ~ 0').split(' ~ ');
    final minBudget = int.tryParse(budgetParts[0]) ?? 0;
    final maxBudget = int.tryParse(budgetParts[1]) ?? 0;

    // Rule 1
    if (answers['Q3'] == 500 && (answers['Q5C'] == '4K' || answers['Q5C'] == '8K' || answers['Q6C'] == '대규모' || answers['Q6C'] == '스튜디오급')) {
      return '고해상도 미디어 파일은 용량이 매우 크므로 500GB는 심각하게 부족하며, 최소 1TB 이상(권장 2TB)이 필요합니다.';
    }

    // Rule 2
    if (answers['Q5C'] == '4K' && (answers['Q3'] == 500 || answers['Q6C'] == '대규모' || answers['Q6C'] == '스튜디오급')) {
      return '4K 작업은 시스템 자원을 많이 소모하며, 특히 SSD 용량과 프로젝트 규모가 클수록 메모리/CPU/GPU 성능이 매우 중요합니다.';
    }

    // Rule 3
    if (answers['Q5C'] == '8K') {
      return '8K는 현존하는 일반 PC 환경에서 최고 사양을 요구합니다. 제공된 모든 견적으로는 원활한 8K 작업이 사실상 불가능합니다.';
    }

    // Rule 4
    if (answers['Q6C'] == '대규모' && (answers['Q3'] == 500 || answers['Q3'] == 1000 || answers['Q5C'] == '4K' || answers['Q5C'] == '8K')) {
      return '대규모 프로젝트는 수백 GB의 용량과 엄청난 시스템 자원을 필요로 합니다. 최소 2TB SSD 및 고성능 CPU/GPU/RAM(64GB 이상)이 필수입니다.';
    }

    // Rule 5
    if (answers['Q6C'] == '스튜디오급') {
      return '\'스튜디오급\' 작업은 전문적인 워크스테이션 수준의 사양(고성능 CPU/GPU, 2TB 이상 SSD, 128GB+ RAM)을 의미하며, 제공된 모든 견적 사양으로는 적합하지 않습니다.';
    }

    // Rule 6
    if (answers['Q7C'] == '실시간' && (answers['Q5C'] == '4K' || answers['Q5C'] == '8K' || answers['Q6C'] == '대규모' || answers['Q6C'] == '스튜디오급')) {
      return '실시간 렌더링은 GPU의 VRAM과 CUDA/Tensor 코어 성능이 매우 중요하며, 제공된 견적 사양으로는 4K 이상에서 불가능합니다.';
    }

    // Rule 7
    if (answers['Q5O'] == '10개 이상' && (answers['Q3'] == 500 || answers['Q3'] == 1000 || answers['Q7O'] == '1TB 미만')) {
      return '10개 이상의 고사양 프로그램을 동시에 실행하려면 최소 32GB RAM(권장 64GB)과 2TB 이상의 고속 SSD가 필요합니다.';
    }

    // Rule 8
    if (answers['Q7O'] == '1TB 이상' && answers['Q3'] == 500) {
      return '저장 공간(Q7O)이 필요한 SSD 용량(Q3)보다 커서, 주 저장 장치로는 부족합니다. 이는 외부 저장소를 필수적으로 가정해야만 가능한 조합입니다.';
    }

    // Rule 9
    if (maxBudget < 50 && (answers['Q4O'] == '데이터분석' || answers['Q5O'] == '10개 이상' || answers['Q7O'] == '1TB 이상')) {
      return '이 예산은 문서/웹서핑(Q4O: ①, ③)용입니다. 데이터 분석(LLM)은 최소 390만원 견적(64GB RAM, RTX 5080)이 필요하며, 10개 이상 실행에는 고용량 RAM이 필수입니다.';
    }

    // Rule 10
    if (maxBudget < 100 && (answers['Q4O'] == '데이터분석' || answers['Q5O'] == '10개 이상' || answers['Q7O'] == '1TB 이상')) {
      return '이 예산은 개발/코딩 입문 정도에 적합합니다. 데이터 분석(LLM)은 불가능하며, 10개 이상 프로그램 실행에 필요한 32GB~64GB RAM 구성이 어렵습니다.';
    }

    // Rule 11
    if (maxBudget < 250 && answers['Q4O'] == '데이터분석') { // Simplified for general data analysis
      return 'LLM 딥러닝에 필요한 고성능 GPU(RTX 5080/5090)와 64GB 이상의 RAM 구성은 최소 390만원 이상이 필요합니다.';
    }

    // Rule 12
    if (maxBudget < 400 && answers['Q4O'] == '데이터분석' && answers['Q5O'] == '10개 이상' && answers['Q7O'] == '1TB 이상') {
      return 'LLM개발용(390만원) 견적의 사양입니다. 이 사양은 고성능이지만, 최고 사양 AI 개발(660만원 견적의 RTX 5090 급)까지 커버하기는 어렵습니다.';
    }

    return null; // No unrealistic combinations found
  }

  HardwareRecommendation? _findBestMatch(EstimateSamples samples, Map<String, dynamic> userAnswers) {
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

      // --- Budget Scoring ---
      if (sample.budget != null) {
        final sampleMin = sample.budget!.min;
        final sampleMax = sample.budget!.max;
        final sampleAvg = (sampleMin + sampleMax) / 2.0;

        // Check for overlap
        if (userMinBudget <= sampleMax && userMaxBudget >= sampleMin) {
          currentScore += 20; // Base score for any overlap
          // Bonus for user average budget falling within sample range
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

      // --- SSD Scoring ---
      final userSsd = userAnswers['Q3'] as int;
      final sampleSsd = int.tryParse(sample.ssd ?? '0') ?? 0;
      if (sampleSsd >= userSsd) {
        currentScore += 10;
      }

      // --- Task Scoring ---
      final usage = userAnswers['Q1'];
      if (sample.task != null) {
        final task = sample.task!;
        
        MapEntry<String, String>? mainUseEntry;
        try {
          mainUseEntry = ( _questionData['Q1']!['options'] as Map<String, String>).entries.firstWhere((e) => e.value == usage);
        } catch (e) {
          mainUseEntry = null;
        }

        String mainUseText = '';
        if (mainUseEntry != null && mainUseEntry.key.length > 2) {
            mainUseText = mainUseEntry.key.substring(2).trim();
        }
        bool mainUseMatches = task.mainUse == null || (mainUseText.isNotEmpty && task.mainUse!.contains(mainUseText));
        
        if(mainUseMatches) {
            currentScore += 10; // Base score for correct main usage

            switch (usage) {
              case 'C': // Creative
                if (task.software != null && userAnswers['Q4C'] != null && task.software!.contains(userAnswers['Q4C'])) currentScore += 20;
                if (task.resolution != null && userAnswers['Q5C'] != null && task.resolution!.contains(userAnswers['Q5C'])) currentScore += 15;
                if (task.scale != null && userAnswers['Q6C'] != null && task.scale!.contains(userAnswers['Q6C'])) currentScore += 10;
                if (task.frequency != null && userAnswers['Q7C'] != null && task.frequency!.contains(userAnswers['Q7C'])) currentScore += 10;
                break;
              case 'O': // Office
                if (task.work != null && userAnswers['Q4O'] != null && task.work!.contains(userAnswers['Q4O'])) currentScore += 20;
                if (task.progs != null && userAnswers['Q5O'] != null && task.progs!.contains(userAnswers['Q5O'])) currentScore += 10;
                if (task.monitors != null && userAnswers['Q6O'] != null && task.monitors!.contains(userAnswers['Q6O'])) currentScore += 10;
                if (task.dataSize != null && userAnswers['Q7O'] != null && task.dataSize!.contains(userAnswers['Q7O'])) currentScore += 10;
                break;
              case 'G': // Gaming
                if (userAnswers['Q4G'] != null && task.gameIds != null) {
                  final userGames = (userAnswers['Q4G'] as String).split(', ');
                  int matchCount = 0;
                  for (var game in userGames) {
                    if (task.gameIds!.contains(game)) {
                      matchCount++;
                    }
                  }
                  currentScore += matchCount * 10; // 10 points per matched game
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

    // If no good match found, fall back to the one with the closest budget.
    if (bestScore < 20 && closestBudgetMatch != null) {
       bestMatch = closestBudgetMatch;
    }

    // Final fallback: if bestMatch is still null (e.g., empty JSON), return at least the closest budget match.
    if (bestMatch == null && closestBudgetMatch != null) {
      bestMatch = closestBudgetMatch;
    }

    return bestMatch?.hardwareRecommendations.first;
  }


  // ---------------------------------------------------------------------------
  // UI BUILDERS
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _history.length > 1 && !_isFinished
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: _onBack)
            : null,
        title: const Text('나만의 PC 견적'),
      ),
      body: _isFinished ? _buildResultView() : _buildQuestionView(),
      bottomNavigationBar: _isFinished ? null : _buildNextButton(),
    );
  }

  Widget _buildQuestionView() {
    final question = _questionData[_currentQCode]!;
    final text = question['text'] as String;
    final options = question['options'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Q${_history.length}. $text', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          if (options == 'BUDGET')
            _buildBudgetQuestion()
          else if (options == 'GAMES')
            _buildGameQuestion()
          else if (options == 'N/A')
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: _questionData[_currentQCode]!['hint'] as String? ?? '답변을 입력하세요',
                border: const OutlineInputBorder(),
              ),
            )
          else
            _buildOptions(options as Map<String, dynamic>),
        ],
      ),
    );
  }

  Widget _buildBudgetQuestion() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _minBudgetController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: '최소',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.0),
          child: Text('~', style: TextStyle(fontSize: 24)),
        ),
        Expanded(
          child: TextField(
            controller: _maxBudgetController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: '최대',
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGameQuestion() {
    return Column(
      children: [
        TextField(
          controller: _game1Controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: '게임 번호 1',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _game2Controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: '게임 번호 2 (선택)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _game3Controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: '게임 번호 3 (선택)',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildOptions(Map<String, dynamic> options) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: options.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final key = options.keys.elementAt(index);
        final value = options[key];
        final isSelected = _answers[_currentQCode] == value;

        return ListTile(
          title: Text(key),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          tileColor: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Theme.of(context).colorScheme.surface,
          selected: isSelected,
          onTap: () => setState(() => _answers[_currentQCode] = value),
        );
      },
    );
  }

  Widget _buildResultView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 80),
              const SizedBox(height: 24),
              Text(
                _error!.startsWith('견적 추천 중') ? '오류가 발생했습니다' : '현실적이지 않은 조합입니다',
                style: Theme.of(context).textTheme.headlineSmall
              ),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _onRestart,
                child: const Text('다시하기'),
              )
            ],
          ),
        ),
      );
    }

    if (_recommendation == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 80),
            const SizedBox(height: 24),
            Text('추천 견적을 찾지 못했습니다.', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            const Text('조건에 맞는 견적이 없습니다. 다시 시도해주세요.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _onRestart,
              child: const Text('다시하기'),
            )
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('회원님을 위한 추천 견적', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildRecommendationCard(_recommendation!),
          const SizedBox(height: 32),
           Center(
             child: ElevatedButton(
              onPressed: _onRestart,
              child: const Text('견적 다시 만들기'),
                       ),
           ),
        ],
      ),
    );
  }
  
  Widget _buildRecommendationCard(HardwareRecommendation rec) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          children: [
            _buildSpecRow(Symbols.developer_board, 'CPU', rec.cpu),
            _buildSpecRow(Symbols.ac_unit, 'CPU 쿨러', rec.cpuCooler),
            _buildSpecRow(Symbols.view_in_ar, '메인보드', rec.mainboard),
            _buildSpecRow(Symbols.memory, '메모리', rec.memory),
            _buildSpecRow(Symbols.screenshot_monitor, '그래픽카드', rec.gpu),
            _buildSpecRow(Symbols.storage, 'SSD', rec.ssd),
            _buildSpecRow(Symbols.desktop_windows, '케이스', rec.pcCase),
            _buildSpecRow(Symbols.power, '파워', rec.psu),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecRow(IconData icon, String title, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(value, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
    );
  }

  Widget _buildNextButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          textStyle: const TextStyle(fontSize: 18),
        ),
        onPressed: _onNext,
        child: Text(_getNextQCode() == 'Q_FINISH' ? '결과 보기' : '다음'),
      ),
    );
  }
}
