import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';

/// Consolidated MyMind page with segmented content placeholders.
class MyMindPage extends StatefulWidget {
  const MyMindPage({super.key});

  @override
  State<MyMindPage> createState() => _MyMindPageState();
}

class _MyMindPageState extends State<MyMindPage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text('내 마음', style: AppTextStyles.h4),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          _buildSegments(),
          const SizedBox(height: 12),
          Expanded(child: _buildPanel()),
        ],
      ),
    );
  }

  Widget _buildSegments() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            _segButton('결과', 0),
            _segButton('저장', 1),
            _segButton('기록', 2),
          ],
        ),
      ),
    );
  }

  Widget _segButton(String label, int idx) {
    final selected = _tab == idx;
    return Expanded(
      child: TextButton(
        onPressed: () => setState(() => _tab = idx),
        style: TextButton.styleFrom(
          foregroundColor: selected ? AppColors.primary : AppColors.textSecondary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: selected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildPanel() {
    switch (_tab) {
      case 0:
        return _ResultPanel();
      case 1:
        return _SavedPanel();
      default:
        return _RecordPanel();
    }
  }
}

class _ResultPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('최근 결과', style: AppTextStyles.h4),
        const SizedBox(height: 12),
        _card('그래프 / 해석 카드 자리', 'S31 / S32 진입 포인트'),
        const SizedBox(height: 12),
        _card('추가 설명', 'GPT Explain BottomSheet 트리거'),
      ],
    );
  }
}

class _SavedPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('저장한 하이라이트', style: AppTextStyles.h4),
        const SizedBox(height: 12),
        _card('저장된 결과가 없습니다.', '검사 후 결과를 저장해 보세요.'),
      ],
    );
  }
}

class _RecordPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('오늘의 기록', style: AppTextStyles.h4),
        const SizedBox(height: 12),
        _card('기록이 없습니다.', '검사 결과나 메모를 남겨 보세요.'),
      ],
    );
  }
}

Widget _card(String title, String subtitle) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.h5),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
      ],
    ),
  );
}
