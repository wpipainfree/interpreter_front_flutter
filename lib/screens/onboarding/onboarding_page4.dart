import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';

/// S01-4: One Sentence Summary CTA.
class OnboardingPage4 extends StatelessWidget {
  final VoidCallback onStart;

  const OnboardingPage4({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Text(
            '한 문장으로\n정리됩니다',
            textAlign: TextAlign.center,
            style: AppTextStyles.h1,
          ),
          const SizedBox(height: 24),
          Text(
            '검사를 마치면, 내 결과가 원자 구조 언어로 먼저 요약됩니다.\n'
            '더 알고 싶으면 결과에서 바로 ‘추가 설명’을 요청하면 됩니다.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(flex: 3),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: onStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                '내 구조 분석 시작',
                style: AppTextStyles.buttonMedium,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
