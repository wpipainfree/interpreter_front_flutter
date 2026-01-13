import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import 'test_note_screen.dart';

class TestIntroScreen extends StatelessWidget {
  const TestIntroScreen({super.key});

  void _start(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const TestNoteScreen(
          testId: 1,
          testTitle: '현실 검사',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text('검사 시작'),
        backgroundColor: AppColors.backgroundWhite,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        automaticallyImplyLeading: canPop,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('준비 1/2', style: AppTextStyles.caption),
              const SizedBox(height: 12),
              Text(
                '정답은 없습니다.\n지금의 나를 있는 그대로 선택해요.',
                style: AppTextStyles.h3,
              ),
              const SizedBox(height: 12),
              Text(
                '다음 단계에서 “알고 싶은 마음”을 1~2줄로 적고 시작합니다.',
                style: AppTextStyles.bodyMedium,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _start(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: AppColors.textOnPrimary,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '검사 시작',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
