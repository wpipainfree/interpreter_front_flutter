import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import 'onboarding_atom_graphic.dart';

/// S01-1: Atom model intro (core + reaction layers).
class OnboardingPage1 extends StatelessWidget {
  const OnboardingPage1({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Text(
            '감정이 아니라\n구조입니다',
            textAlign: TextAlign.center,
            style: AppTextStyles.h1,
          ),
          const SizedBox(height: 28),
          const OnboardingAtomGraphic(showCoreLabels: true),
          const SizedBox(height: 28),
          Text(
            '마음은 감정이 아닙니다.\n'
            '기준과 믿음이 중심이고, 감정과 몸은 그 충돌이 드러나는 반응입니다.\n'
            'WPI는 이 구조를 ‘영상처럼’ 보여주는 마음의 MRI입니다.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
