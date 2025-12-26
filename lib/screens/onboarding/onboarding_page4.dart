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
            'One Sentence\nSummary',
            textAlign: TextAlign.center,
            style: AppTextStyles.h1,
          ),
          const SizedBox(height: 24),
          Text(
            'Here are the concise insights that capture\nthe structure beneath your story.',
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
                'Analyze My Structure',
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
