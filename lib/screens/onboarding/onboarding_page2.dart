import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';

/// S01-2: Reality vs Ideal.
class OnboardingPage2 extends StatelessWidget {
  const OnboardingPage2({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _pillCard(
                label: 'Reality',
                fillColor: AppColors.secondary,
                textColor: Colors.white,
                outline: false,
              ),
              Container(
                width: 1,
                height: 120,
                margin: const EdgeInsets.symmetric(horizontal: 28),
                color: AppColors.border,
              ),
              _pillCard(
                label: 'Ideal',
                fillColor: Colors.transparent,
                textColor: AppColors.primary,
                outline: true,
              ),
            ],
          ),
          const Spacer(),
          Text(
            'Clarify the concept between what is and what should be,\nthen interpret the gap through your own structure.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 36),
        ],
      ),
    );
  }

  Widget _pillCard({
    required String label,
    required Color fillColor,
    required Color textColor,
    required bool outline,
  }) {
    return Container(
      width: 120,
      height: 170,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: outline ? Colors.transparent : fillColor,
        border: outline ? Border.all(color: AppColors.primary, width: 2) : null,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: AppTextStyles.h4.copyWith(
          color: textColor,
          fontSize: 18,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
