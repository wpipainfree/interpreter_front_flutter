import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';

/// S01-2: Reality + Ideal overview with CTA.
class OnboardingPage2 extends StatelessWidget {
  const OnboardingPage2({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Text(
            '내 구조를\n확인해보세요',
            textAlign: TextAlign.center,
            style: AppTextStyles.h1,
          ),
          const SizedBox(height: 16),
          Text(
            '현실은 지금 나를 지탱하는 기준과 믿음을 확인합니다.\n'
            '이상은 내가 향하는 변화 방향을 확인합니다(회복/도피는 해석에서 정리).\n'
            '검사 후 결과는 먼저 요약으로 보고, 더 궁금하면 추가 설명을 요청하면 됩니다.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
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
                '내 마음의 MRI 보기',
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
