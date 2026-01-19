import 'package:flutter/material.dart';

import '../../../../utils/app_colors.dart';
import '../../../../utils/app_text_styles.dart';

class AtomHeaderCard extends StatelessWidget {
  const AtomHeaderCard({
    super.key,
    required this.typeLabel,
    required this.stateLabel,
    required this.assetPath,
  });

  final String typeLabel;
  final String stateLabel;
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.asset(
              assetPath,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.backgroundLight,
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.image_outlined,
                      size: 32,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$typeLabel · $stateLabel',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetaChip(text: '유형: $typeLabel'),
                _MetaChip(text: '핵 기울기: $stateLabel'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Text(
              '현실 구조를 한 장으로 요약한 그림입니다.',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

