import 'package:flutter/material.dart';

import '../../../../utils/app_colors.dart';
import '../../../../utils/app_text_styles.dart';

class ScoreTable extends StatelessWidget {
  const ScoreTable({
    super.key,
    required this.selfLabels,
    required this.selfScores,
    required this.otherLabels,
    required this.otherScores,
  });

  final List<String> selfLabels;
  final List<double?> selfScores;
  final List<String> otherLabels;
  final List<double?> otherScores;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TableSection(
          title: '자기평가',
          titleColor: Colors.red,
          headerBg: const Color(0xFFFFEEF2),
          labels: selfLabels,
          scores: selfScores,
        ),
        const SizedBox(height: 12),
        _TableSection(
          title: '타인평가',
          titleColor: Colors.blue,
          headerBg: const Color(0xFFE8EDFF),
          labels: otherLabels,
          scores: otherScores,
        ),
      ],
    );
  }
}

class _TableSection extends StatelessWidget {
  const _TableSection({
    required this.title,
    required this.titleColor,
    required this.headerBg,
    required this.labels,
    required this.scores,
  });

  final String title;
  final Color titleColor;
  final Color headerBg;
  final List<String> labels;
  final List<double?> scores;

  @override
  Widget build(BuildContext context) {
    final columnWidths = <int, TableColumnWidth>{};
    for (var i = 0; i < labels.length; i++) {
      columnWidths[i] = const FlexColumnWidth();
    }
    const cellPadding = EdgeInsets.symmetric(horizontal: 6, vertical: 10);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            color: headerBg,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                color: titleColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.border),
          Table(
            columnWidths: columnWidths,
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            border: TableBorder.symmetric(
              inside: const BorderSide(color: AppColors.border, width: 1),
            ),
            children: [
              TableRow(
                children: labels
                    .map(
                      (label) => Padding(
                        padding: cellPadding,
                        child: Text(
                          label,
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                    .toList(),
              ),
              TableRow(
                children: scores
                    .map(
                      (score) => Padding(
                        padding: cellPadding,
                        child: Text(
                          score != null
                              ? score.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')
                              : '-',
                          style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

