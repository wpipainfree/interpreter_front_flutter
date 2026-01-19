import 'package:flutter/material.dart';

import '../../../../utils/app_text_styles.dart';

class ScoreLegend extends StatelessWidget {
  const ScoreLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendDot(color: Colors.red, label: '자기평가'),
        SizedBox(width: 16),
        _LegendDot(color: Colors.blue, label: '타인평가'),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.bodySmall),
      ],
    );
  }
}

