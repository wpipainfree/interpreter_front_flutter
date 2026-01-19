import 'package:flutter/material.dart';

import '../../../../utils/app_colors.dart';
import '../../../../utils/app_text_styles.dart';

class ResultSectionHeader extends StatelessWidget {
  const ResultSectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.h4),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

