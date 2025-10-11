// lib/screens/my_estimate_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:picom/models/estimate_sample_model.dart';
import 'package:picom/models/spec_profile.dart';
import 'package:picom/services/recommendation_service.dart';
import 'pc_assembly_screen.dart';

class MyEstimateScreen extends StatefulWidget {
  const MyEstimateScreen({super.key});
  @override
  State<MyEstimateScreen> createState() => _MyEstimateScreenState();
}

class _MyEstimateScreenState extends State<MyEstimateScreen> {
  final RecommendationService _recommendationService = RecommendationService();
  static const Map<String, Map<String, dynamic>> _questionData = { 'Q1': { 'text': '컴퓨터의 주된 용도는?', 'options': {'① 게임': 'G', '② 창작작업': 'C', '③ 사무·개발': 'O'},}, 'Q2': { 'text': '예산 범위 (만원 단위)', 'options': 'BUDGET', }, 'Q3': { 'text': '필요한 SSD 용량 (GB)', 'options': {'① 500': 500, '② 1000': 1000, '③ 2000': 2000, '④ 그 이상': 9999},}, 'Q4G': { 'text': '즐기실 게임 번호 선택 (최대 3개)', 'options': 'GAMES', 'hint': '1~154번 사이의 게임 번호를 입력하세요',}, 'Q5G': { 'text': '현재 모니터 해상도', 'options': {'① FHD': 'FHD', '② QHD': 'QHD', '③ 4K': '4K'},}, 'Q6G': { 'text': '원하는 평균 FPS', 'options': {'① 60': 60, '② 100': 100, '③ 120': 120, '④ 144': 144, '⑤ 165': 165, '⑥ 240': 240},}, 'Q7G': { 'text': '선호하는 그래픽 품질', 'options': {'① 낮음': '낮음', '② 보통': '보통', '③ 높음': '높음', '④ 최고': '최고', '⑤ 레이트레이싱': '레이트레이싱'},}, 'Q4C': { 'text': '주로 사용하는 소프트웨어', 'options': {'① 프리미어': '프리미어', '② 블렌더': '블렌더', '③ 포토샵/라이트룸': '포토샵/라이트룸', '④ AE': 'AE', '⑤ C4D': 'C4D', '⑥ 기타': '기타'},}, 'Q5C': { 'text': '작업 영상/이미지 해상도', 'options': {'① FHD': 'FHD', '② QHD': 'QHD', '③ 4K': '4K', '④ 8K': '8K'},}, 'Q6C': { 'text': '프로젝트 규모', 'options': {'① 개인': '개인', '② 소규모': '소규모', '③ 대규모': '대규모', '④ 스튜디오급': '스튜디오급'},}, 'Q7C': { 'text': '렌더링 빈도', 'options': {'① 가끔': '가끔', '② 자주': '자주', '③ 실시간': '실시간'},}, 'Q4O': { 'text': '주된 업무', 'options': {'① 문서': '문서', '② 개발/코딩': '개발/코딩', '③ 웹서핑/이메일': '웹서핑/이메일', '④ 데이터분석': '데이터분석', '⑤ 기타': '기타'},}, 'Q5O': { 'text': '동시에 실행할 프로그램 수', 'options': {'① 5개 미만': '5개 미만', '② 5~10개': '5~10개', '③ 10개 이상': '10개 이상'},}, 'Q6O': { 'text': '사용할 모니터 개수', 'options': {'① 1개': '1개', '② 2개': '2개', '③ 3개 이상': '3개 이상'},}, 'Q7O': { 'text': '저장할 데이터 규모', 'options': {'① 100GB 미만': '100GB 미만', '② 1TB 미만': '1TB 미만', '③ 1TB 이상': '1TB 이상'},},};
  final List<String> _history = ['Q1'];
  final Map<String, dynamic> _answers = {};
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _minBudgetController = TextEditingController();
  final TextEditingController _maxBudgetController = TextEditingController();
  final TextEditingController _game1Controller = TextEditingController();
  final TextEditingController _game2Controller = TextEditingController();
  final TextEditingController _game3Controller = TextEditingController();

  SpecProfile? _specProfile;
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

  String _getNextQCode() {
    switch (_currentQCode) {
      case 'Q1': return 'Q2';
      case 'Q2': return 'Q3';
      case 'Q3': final usage = _answers['Q1']; return 'Q4$usage';
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
      if (min.isEmpty || max.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('최소값과 최대값을 모두 입력해주세요.'))); return; }
      final minVal = int.tryParse(min) ?? 0;
      final maxVal = int.tryParse(max) ?? 0;
      if (minVal > maxVal) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('최소값은 최대값보다 클 수 없습니다.'))); return; }
      answer = '$min ~ $max';
    } else if (_currentQCode == 'Q4G') {
      final games = [_game1Controller.text.trim(), _game2Controller.text.trim(), _game3Controller.text.trim(),].where((g) => g.isNotEmpty).toList();
      if (games.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('하나 이상의 게임 번호를 입력해주세요.'))); return; }
      answer = games.join(', ');
    } else if (currentQuestion['options'] == 'N/A') {
      if (_textController.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('답변을 입력해주세요.'))); return; }
      answer = _textController.text.trim();
    } else {
      if (!_answers.containsKey(_currentQCode)) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('답변을 선택해주세요.'))); return; }
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
        _specProfile = null;
        _error = null;
        final lastQ = _history.removeLast();
        _answers.remove(lastQ);
        _textController.clear(); _minBudgetController.clear(); _maxBudgetController.clear(); _game1Controller.clear(); _game2Controller.clear(); _game3Controller.clear();
        final prevQ = _questionData[_currentQCode]!;
        final prevAnswer = _answers[_currentQCode];
        if (prevAnswer != null) {
          if (_currentQCode == 'Q2') {
            final parts = prevAnswer.toString().split(' ~ ');
            if (parts.length == 2) { _minBudgetController.text = parts[0]; _maxBudgetController.text = parts[1]; }
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
      _history.clear(); _history.add('Q1'); _answers.clear(); _textController.clear(); _minBudgetController.clear(); _maxBudgetController.clear(); _game1Controller.clear(); _game2Controller.clear(); _game3Controller.clear();
      _specProfile = null; _isLoading = false; _error = null;
    });
  }

  Future<void> _processResults() async {
    setState(() { _isLoading = true; _error = null; _specProfile = null; });
    try {
      final specProfile = await _recommendationService.getProfileForUserAnswers(_answers);
      setState(() {
        _specProfile = specProfile;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _history.length > 1 && !_isFinished ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: _onBack) : null,
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
          if (options == 'BUDGET') _buildBudgetQuestion()
          else if (options == 'GAMES') _buildGameQuestion()
          else if (options == 'N/A') TextField(controller: _textController, decoration: InputDecoration(hintText: _questionData[_currentQCode]!['hint'] as String? ?? '답변을 입력하세요', border: const OutlineInputBorder(),),)
            else _buildOptions(options as Map<String, dynamic>),
        ],
      ),
    );
  }

  Widget _buildBudgetQuestion() {
    return Row(children: [ Expanded(child: TextField(controller: _minBudgetController, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: '최소', border: OutlineInputBorder(),),),), const Padding(padding: EdgeInsets.symmetric(horizontal: 12.0), child: Text('~', style: TextStyle(fontSize: 24)),), Expanded(child: TextField(controller: _maxBudgetController, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: '최대', border: OutlineInputBorder(),),),), ],);
  }

  Widget _buildGameQuestion() {
    return Column(children: [ TextField(controller: _game1Controller, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: '게임 번호 1', border: OutlineInputBorder(),),), const SizedBox(height: 12), TextField(controller: _game2Controller, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: '게임 번호 2 (선택)', border: OutlineInputBorder(),),), const SizedBox(height: 12), TextField(controller: _game3Controller, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: '게임 번호 3 (선택)', border: OutlineInputBorder(),),), ],);
  }

  Widget _buildOptions(Map<String, dynamic> options) {
    return ListView.separated(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: options.length, separatorBuilder: (_, __) => const SizedBox(height: 12), itemBuilder: (context, index) { final key = options.keys.elementAt(index); final value = options[key]; final isSelected = _answers[_currentQCode] == value; return ListTile(title: Text(key), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), tileColor: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Theme.of(context).colorScheme.surface, selected: isSelected, onTap: () => setState(() => _answers[_currentQCode] = value),);},);
  }

  Widget _buildResultView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [ const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 80), const SizedBox(height: 24), Text('현실적이지 않은 조합입니다', style: Theme.of(context).textTheme.headlineSmall), const SizedBox(height: 12), Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)), const SizedBox(height: 24), ElevatedButton(onPressed: _onRestart, child: const Text('다시하기'),) ],),),);
    }
    if (_specProfile == null || _specProfile!.recommendationText == null) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [ const Icon(Icons.error_outline, color: Colors.red, size: 80), const SizedBox(height: 24), Text('추천 견적을 찾지 못했습니다.', style: Theme.of(context).textTheme.headlineSmall), const SizedBox(height: 12), const Text('조건에 맞는 견적이 없습니다. 다시 시도해주세요.', style: TextStyle(color: Colors.grey)), const SizedBox(height: 24), ElevatedButton(onPressed: _onRestart, child: const Text('다시하기'),) ],),);
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('회원님을 위한 추천 견적', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('이 견적은 신제품 기준이며, 실제 중고 부품 재고에 따라 구성이 달라질 수 있습니다.', style: TextStyle(color: Colors.grey),),
          const SizedBox(height: 24),
          _buildRecommendationCard(_specProfile!.recommendationText!),
          const SizedBox(height: 32),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(icon: const Icon(Icons.search), label: const Text('이 사양으로 중고 부품 찾기'), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white,), onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (context) => PcAssemblyScreen(specProfile: _specProfile),),);},),),
          const SizedBox(height: 16),
          Center(child: TextButton(onPressed: _onRestart, child: const Text('견적 다시 만들기'),),),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(HardwareRecommendation rec) {
    return Card(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Column(children: [ _buildSpecRow(Symbols.developer_board, 'CPU', rec.cpu), _buildSpecRow(Symbols.ac_unit, 'CPU 쿨러', rec.cpuCooler), _buildSpecRow(Symbols.view_in_ar, '메인보드', rec.mainboard), _buildSpecRow(Symbols.memory, '메모리', rec.memory), _buildSpecRow(Symbols.screenshot_monitor, '그래픽카드', rec.gpu), _buildSpecRow(Symbols.storage, 'SSD', rec.ssd), _buildSpecRow(Symbols.desktop_windows, '케이스', rec.pcCase), _buildSpecRow(Symbols.power, '파워', rec.psu), ],),),);
  }

  Widget _buildSpecRow(IconData icon, String title, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return ListTile(leading: Icon(icon, color: Theme.of(context).colorScheme.primary), title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(value, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),);
  }

  Widget _buildNextButton() {
    return Padding(padding: const EdgeInsets.all(16.0), child: ElevatedButton(style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), textStyle: const TextStyle(fontSize: 18),), onPressed: _onNext, child: Text(_getNextQCode() == 'Q_FINISH' ? '결과 보기' : '다음'),),);
  }
}