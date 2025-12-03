import 'package:flutter/material.dart';
import '../../models/wpi_result.dart';
import '../../services/notification_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../result/result_summary_screen.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final List<String> _questions = List.generate(
    AppConstants.sampleQuestionCount,
    (index) => '문항 ${index + 1}. 지금의 감정 상태를 가장 잘 설명하는 선택지를 고르세요.',
  );
  int _currentQuestion = 0;
  final Map<int, int> _answers = {};

  void _next() async {
    if (_currentQuestion == _questions.length - 1) {
      final result = _mockResult();
      
      await NotificationService().showTestCompleteNotification(
        existenceType: result.existenceType,
      );
      
      if (!mounted) return;
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
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        title: const Text(
          'WPI 검사',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '나가기',
              style: TextStyle(color: AppColors.textHint),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 진행률 표시
          LinearProgressIndicator(
            value: current / total,
            backgroundColor: AppColors.divider,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
            minHeight: 6,
          ),
          
          // 문항 번호
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '문항 $current / $total',
              style: const TextStyle(color: AppColors.textTertiary),
            ),
          ),
          
          // 질문 및 옵션
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Q$current',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _questions[_currentQuestion],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ..._buildOptions(),
                ],
              ),
            ),
          ),
          
          // 하단 버튼
          _buildBottomButtons(current, total),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(int current, int total) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          if (_currentQuestion > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previous,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                ),
                child: const Text('이전'),
              ),
            ),
          if (_currentQuestion > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _answers.containsKey(_currentQuestion) ? _next : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                minimumSize: const Size(0, 48),
              ),
              child: Text(current == total ? '완료' : '다음'),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildOptions() {
    return AppConstants.likertOptions.asMap().entries.map((entry) {
      final idx = entry.key;
      final text = entry.value;
      final selected = _answers[_currentQuestion] == idx;
      
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          onTap: () => setState(() => _answers[_currentQuestion] = idx),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: selected ? AppColors.secondary : AppColors.divider,
                width: selected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(10),
              color: selected ? AppColors.secondary.withOpacity(0.1) : AppColors.backgroundWhite,
            ),
            child: Row(
              children: [
                _buildRadioButton(selected),
                const SizedBox(width: 12),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 15,
                    color: selected ? AppColors.secondary : AppColors.textSecondary,
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

  Widget _buildRadioButton(bool selected) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.secondary : AppColors.disabled,
          width: 2,
        ),
        color: selected ? AppColors.secondary : Colors.transparent,
      ),
      child: selected
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : null,
    );
  }
}
