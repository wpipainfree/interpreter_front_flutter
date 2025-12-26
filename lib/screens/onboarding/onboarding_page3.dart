import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';

/// S01-3: Venn diagram of I vs ME.
class OnboardingPage3 extends StatelessWidget {
  const OnboardingPage3({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Spacer(),
          SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 24,
                  child: _circle(AppColors.primary, 'I\n(Belief)'),
                ),
                Positioned(
                  right: 24,
                  child: _circle(AppColors.secondary, 'ME\n(Standard)'),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            'Explore the space where belief and standards intersect.\nYour analytical diagram of inner structure.',
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

  Widget _circle(Color color, String label) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.6),
        color: color.withOpacity(0.06),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: AppTextStyles.labelLarge.copyWith(color: color),
      ),
    );
  }
}
