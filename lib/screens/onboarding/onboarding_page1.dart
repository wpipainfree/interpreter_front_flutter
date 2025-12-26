import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';

/// S01-1: From Chaos to Structure.
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
            'From Chaos\nto Structure.',
            textAlign: TextAlign.center,
            style: AppTextStyles.h1,
          ),
          const SizedBox(height: 32),
          _ChaosGraphic(),
          const SizedBox(height: 32),
          Text(
            'Concise, psychological valuation and inner structure.\nInk-on-paper calm with clear focus.',
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

class _ChaosGraphic extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                14,
                (index) => Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 28),
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.secondary,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
