import 'package:flutter/material.dart';

// Enum for Q1 choices to make branching clearer
enum ComputerUsage { game, creative, office, mixed }

class MyEstimateScreen extends StatefulWidget {
  const MyEstimateScreen({super.key});

  @override
  State<MyEstimateScreen> createState() => _MyEstimateScreenState();
}

class _MyEstimateScreenState extends State<MyEstimateScreen> {
  final Map<String, dynamic> _answers = {};
  final Map<String, TextEditingController> _textControllers = {};

  // Holds the key of the current question and the history for back navigation
  final List<String> _questionHistory = ['Q1'];
  String get _currentQuestionKey => _questionHistory.last;

  @override
  void dispose() {
    _textControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void _handleNext() {
    // --- VALIDATION AND ANSWER SAVING --- //
    bool validationPassed = false;
    switch (_currentQuestionKey) {
      case 'Q2': // Budget
        final minText = _textControllers['Q2_min']!.text.trim();
        final maxText = _textControllers['Q2_max']!.text.trim();
        if (minText.isEmpty || maxText.isEmpty) {
          _showError('예산을 입력해주세요.');
          return;
        }
        final minVal = int.tryParse(minText);
        final maxVal = int.tryParse(maxText);
        if (minVal == null || maxVal == null) {
          _showError('숫자만 입력해주세요.');
          return;
        }
        if (maxVal < minVal) {
          _showError('최대값은 최소값보다 작을 수 없습니다.');
          return;
        }
        _answers[_currentQuestionKey] = {'min': minVal, 'max': maxVal};
        validationPassed = true;
        break;

      case 'Q4G': // Game Numbers
        final text = _textControllers[_currentQuestionKey]!.text.trim();
        if (text.isEmpty) {
          _showError('답변을 입력해주세요.');
          return;
        }
        final parts = text.split(',');
        final List<int> gameNumbers = [];
        for (final part in parts) {
          final num = int.tryParse(part.trim());
          if (num == null) {
            _showError('숫자와 쉼표(,)만 사용하여 올바르게 입력해주세요.');
            return;
          }
          gameNumbers.add(num);
        }
        if (gameNumbers.any((num) => num > 154 || num < 1)) {
          _showError('게임 번호는 1에서 154 사이여야 합니다.');
          return;
        }
        if (gameNumbers.toSet().length != gameNumbers.length) {
          _showError('중복된 게임 번호를 입력할 수 없습니다.');
          return;
        }
        _answers[_currentQuestionKey] = gameNumbers;
        validationPassed = true;
        break;

      case 'Q4M': // Representative Game Number
        final text = _textControllers[_currentQuestionKey]!.text.trim();
        if (text.isEmpty) {
          _showError('답변을 입력해주세요.');
          return;
        }
        final num = int.tryParse(text);
        if (num == null) {
          _showError('숫자만 입력해주세요.');
          return;
        }
        if (num > 154 || num < 1) {
          _showError('게임 번호는 1에서 154 사이여야 합니다.');
          return;
        }
        _answers[_currentQuestionKey] = num;
        validationPassed = true;
        break;

      default:
        // For multiple choice questions, the answer is already in the map.
        if (_answers.containsKey(_currentQuestionKey)) {
          validationPassed = true;
        } else {
          _showError('답변을 선택해주세요.');
          return;
        }
        break;
    }

    if (!validationPassed) return;

    // --- NAVIGATION --- //
    final nextQuestionKey = _determineNextQuestionKey();
    if (nextQuestionKey != null) {
      setState(() {
        _questionHistory.add(nextQuestionKey);
      });
    } else {
      // End of survey
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('설문 완료!'), duration: Duration(seconds: 2)),
      );
      print("Final Answers: $_answers");
    }
  }

  void _handleBack() {
    if (_questionHistory.length > 1) {
      setState(() {
        final removedKey = _questionHistory.removeLast();
        _answers.remove(removedKey);
      });
    }
  }

  String? _determineNextQuestionKey() {
    switch (_currentQuestionKey) {
      case 'Q1': return 'Q2';
      case 'Q2': return 'Q3';
      case 'Q3':
        final usage = _answers['Q1'];
        switch (usage) {
          case ComputerUsage.game: return 'Q4G';
          case ComputerUsage.creative: return 'Q4C';
          case ComputerUsage.office: return 'Q4O';
          case ComputerUsage.mixed: return 'Q4M';
        }
      case 'Q4G': return 'Q5G';
      case 'Q5G': return 'Q6G';
      case 'Q6G': return 'Q7G';
      case 'Q4C': return 'Q5C';
      case 'Q5C': return 'Q6C';
      case 'Q6C': return 'Q7C';
      case 'Q4O': return 'Q5O';
      case 'Q5O': return 'Q6O';
      case 'Q6O': return 'Q7O';
      case 'Q4M': return 'Q5M';
      case 'Q5M': return 'Q6M';
      default: return null; // End of survey
    }
  }

  Widget _buildQuestionByKey(String key) {
    switch (key) {
      case 'Q1':
        return _buildMultipleChoiceQuestion(
          questionKey: 'Q1', question: "컴퓨터의 주된 용도는?",
          options: {"게임": ComputerUsage.game, "창작작업": ComputerUsage.creative, "사무·개발": ComputerUsage.office, "혼합": ComputerUsage.mixed},
          onSelected: (value) => setState(() => _answers['Q1'] = value),
        );
      case 'Q2': return _buildBudgetQuestion();
      case 'Q3':
        return _buildMultipleChoiceQuestion(
          questionKey: 'Q3', question: "필요한 SSD 용량 (GB)",
          options: {"500": 500, "1000": 1000, "2000": 2000, "그 이상": -1},
          onSelected: (value) => setState(() => _answers['Q3'] = value),
        );
      // Game Branch
      case 'Q4G': return _buildTextQuestion(question: "즐기실 게임 번호 선택 (최대 3개, 1~154번)", questionKey: 'Q4G');
      case 'Q5G': return _buildMultipleChoiceQuestion(questionKey: 'Q5G', question: "현재 모니터 해상도", options: {"FHD": "FHD", "QHD": "QHD", "4K": "4K"}, onSelected: (value) => setState(() => _answers['Q5G'] = value));
      case 'Q6G': return _buildMultipleChoiceQuestion(questionKey: 'Q6G', question: "원하는 평균 FPS", options: {"60": 60, "100": 100, "120": 120, "144": 144, "165": 165, "240": 240}, onSelected: (value) => setState(() => _answers['Q6G'] = value));
      case 'Q7G': return _buildMultipleChoiceQuestion(questionKey: 'Q7G', question: "선호하는 그래픽 품질", options: {"낮음": 1, "보통": 2, "높음": 3, "최고": 4, "레이트레이싱": 5}, onSelected: (value) => setState(() => _answers['Q7G'] = value));
      // Creative Branch
      case 'Q4C': return _buildMultipleChoiceQuestion(questionKey: 'Q4C', question: "주로 사용하는 소프트웨어", options: {"프리미어": "premiere", "블렌더": "blender", "포토샵/라이트룸": "photoshop", "AE": "ae", "C4D": "c4d", "기타": "other"}, onSelected: (value) => setState(() => _answers['Q4C'] = value));
      case 'Q5C': return _buildMultipleChoiceQuestion(questionKey: 'Q5C', question: "작업 영상/이미지 해상도", options: {"FHD": "FHD", "QHD": "QHD", "4K": "4K", "8K": "8K"}, onSelected: (value) => setState(() => _answers['Q5C'] = value));
      case 'Q6C': return _buildMultipleChoiceQuestion(questionKey: 'Q6C', question: "프로젝트 규모", options: {"개인": "personal", "소규모": "small", "대규모": "large", "스튜디오급": "studio"}, onSelected: (value) => setState(() => _answers['Q6C'] = value));
      case 'Q7C': return _buildMultipleChoiceQuestion(questionKey: 'Q7C', question: "렌더링 빈도", options: {"가끔": "occasional", "자주": "frequent", "실시간": "realtime"}, onSelected: (value) => setState(() => _answers['Q7C'] = value));
      // Office Branch
      case 'Q4O': return _buildMultipleChoiceQuestion(questionKey: 'Q4O', question: "주된 업무", options: {"문서": "documents", "개발/코딩": "development", "웹서핑/이메일": "web", "데이터분석": "data", "기타": "other"}, onSelected: (value) => setState(() => _answers['Q4O'] = value));
      case 'Q5O': return _buildMultipleChoiceQuestion(questionKey: 'Q5O', question: "동시에 실행할 프로그램 수", options: {"5개 미만": "<5", "5~10개": "5-10", "10개 이상": ">10"}, onSelected: (value) => setState(() => _answers['Q5O'] = value));
      case 'Q6O': return _buildMultipleChoiceQuestion(questionKey: 'Q6O', question: "사용할 모니터 개수", options: {"1개": 1, "2개": 2, "3개 이상": 3}, onSelected: (value) => setState(() => _answers['Q6O'] = value));
      case 'Q7O': return _buildMultipleChoiceQuestion(questionKey: 'Q7O', question: "저장할 데이터 규모", options: {"100GB 미만": "<100GB", "1TB 미만": "<1TB", "1TB 이상": ">=1TB"}, onSelected: (value) => setState(() => _answers['Q7O'] = value));
      // Mixed Branch
      case 'Q4M': return _buildTextQuestion(question: "대표 게임 번호 입력 (예: 39)", questionKey: 'Q4M');
      case 'Q5M': return _buildMultipleChoiceQuestion(questionKey: 'Q5M', question: "대표 작업 선택", options: {"영상편집": "video", "3D 모델링": "3d", "디자인": "design", "개발/코딩": "dev"}, onSelected: (value) => setState(() => _answers['Q5M'] = value));
      case 'Q6M': return _buildMultipleChoiceQuestion(questionKey: 'Q6M', question: "게임:작업 비율", options: {"8:2": "8:2", "6:4": "6:4", "5:5": "5:5", "4:6": "4:6", "2:8": "2:8"}, onSelected: (value) => setState(() => _answers['Q6M'] = value));
      default: return Center(child: Text("설문조사가 완료되었습니다. 최종 답변: $_answers"));
    }
  }

  Widget _buildMultipleChoiceQuestion({ required String questionKey, required String question, required Map<String, dynamic> options, required ValueChanged<dynamic> onSelected }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        ...options.entries.map((entry) {
          final isSelected = _answers[questionKey] == entry.value;
          return GestureDetector(
            onTap: () => onSelected(entry.value),
            child: Container(
              width: double.infinity, padding: const EdgeInsets.all(16.0), margin: const EdgeInsets.symmetric(vertical: 6.0),
              decoration: BoxDecoration(
                color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.transparent,
                border: Border.all(color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade400, width: 1.5),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(entry.key, style: const TextStyle(fontSize: 16)),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBudgetQuestion() {
    const minKey = 'Q2_min';
    const maxKey = 'Q2_max';
    _textControllers.putIfAbsent(minKey, () => TextEditingController());
    _textControllers.putIfAbsent(maxKey, () => TextEditingController());
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("예산 범위 (만원 단위)", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: TextField(controller: _textControllers[minKey]!, decoration: const InputDecoration(labelText: "최소", border: OutlineInputBorder()), keyboardType: TextInputType.number)),
          const SizedBox(width: 10), const Text("~"), const SizedBox(width: 10),
          Expanded(child: TextField(controller: _textControllers[maxKey]!, decoration: const InputDecoration(labelText: "최대", border: OutlineInputBorder()), keyboardType: TextInputType.number)),
        ]),
      ],
    );
  }

  Widget _buildTextQuestion({ required String question, required String questionKey }) {
    _textControllers.putIfAbsent(questionKey, () => TextEditingController());
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        TextField(controller: _textControllers[questionKey]!, decoration: const InputDecoration(border: OutlineInputBorder())),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _questionHistory.length > 1 ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: _handleBack) : null,
        title: const Text('나만의 견적'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: _buildQuestionByKey(_currentQuestionKey),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
          onPressed: _handleNext,
          child: Text(_determineNextQuestionKey() == null ? '완료' : '다음'),
        ),
      ),
    );
  }
}