import 'package:flutter/material.dart';
import '../models/wpi_result.dart';
import 'result_summary_screen.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final List<String> _questions = List.generate(
    10,
    (index) => '문항 ${index + 1}. 지금의 감정 상태를 가장 잘 설명하는 선택지를 고르세요.',
  );
  int _currentQuestion = 0;
  final Map<int, int> _answers = {};

  void _next() {
    if (_currentQuestion == _questions.length - 1) {
      final result = _mockResult();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ResultSummaryScreen(result: result),
        ),
      );
      return;
    }
    setState(() => _currentQuestion += 1);
  }

  void _previous() {
    if (_currentQuestion == 0) return;
    setState(() => _currentQuestion -= 1);
  }

  WpiResult _mockResult() {
    return const WpiResult(
      existenceType: '조화형',
      coreMessage: '당신은 내면의 기준과 자기 믿음이 균형을 이루고 있습니다.',
      redLineValue: 0.68,
      redLineDescription: '자기 믿음이 안정적으로 유지됩니다.',
      blueLineValue: 0.55,
      blueLineDescription: '내면화된 기준이 비교적 유연합니다.',
      gapAnalysis: '두 지표 간 차이가 낮아 스트레스에 대한 회복력이 높습니다.',
      emotionalSignals: ['안정감', '호기심', '차분함'],
      bodySignals: ['어깨 이완', '심박수 안정', '규칙적인 호흡'],
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _questions.length;
    final current = _currentQuestion + 1;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('WPI 검사', style: TextStyle(color: Color(0xFF1A1A2E))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('나가기', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: current / total,
            backgroundColor: const Color(0xFFE0E0E0),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
            minHeight: 6,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('문항 $current / $total', style: const TextStyle(color: Color(0xFF666666))),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Q$current',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.bold,
                      )),
                  const SizedBox(height: 16),
                  Text(
                    _questions[_currentQuestion],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1A2E),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ..._buildOptions(),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                if (_currentQuestion > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previous,
                      child: const Text('이전'),
                    ),
                  ),
                if (_currentQuestion > 0) const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _answers.containsKey(_currentQuestion)
                        ? _next
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      minimumSize: const Size(0, 48),
                    ),
                    child: Text(current == total ? '완료' : '다음'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildOptions() {
    const options = [
      '전혀 그렇지 않다',
      '그렇지 않다',
      '보통이다',
      '그렇다',
      '매우 그렇다',
    ];
    return options.asMap().entries.map((entry) {
      final idx = entry.key;
      final text = entry.value;
      final selected = _answers[_currentQuestion] == idx;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: () => setState(() => _answers[_currentQuestion] = idx),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: selected ? const Color(0xFF2E7D32) : const Color(0xFFE0E0E0),
                width: selected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
              color: selected ? const Color(0xFFE8F5E9) : Colors.white,
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? const Color(0xFF2E7D32) : const Color(0xFFBDBDBD),
                      width: 2,
                    ),
                    color: selected ? const Color(0xFF2E7D32) : Colors.transparent,
                  ),
                  child: selected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 16),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    color: selected ? const Color(0xFF1B5E20) : const Color(0xFF424242),
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
}
