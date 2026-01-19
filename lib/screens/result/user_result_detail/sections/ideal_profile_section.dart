import 'package:flutter/material.dart';

import '../../../../services/psych_tests_service.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/app_text_styles.dart';
import '../profile_helpers.dart';
import '../widgets/interactive_line_chart.dart';
import '../widgets/result_section_header.dart';
import '../widgets/score_legend.dart';
import '../widgets/score_table.dart';

class IdealProfileSection extends StatelessWidget {
  const IdealProfileSection({
    super.key,
    required this.detail,
    required this.selfLabels,
    required this.otherLabels,
  });

  final UserResultDetail? detail;
  final List<String> selfLabels;
  final List<String> otherLabels;

  @override
  Widget build(BuildContext context) {
    final result = detail;
    if (result == null) {
      return const ResultSectionHeader(
        title: '이상 프로파일(변화 방향)',
        subtitle: '이상 결과가 없습니다.',
      );
    }

    final selfScores = extractScores(
      result.classes,
      selfLabels,
      checklistNameContains: '자기',
    );
    final otherScores = extractScores(
      result.classes,
      otherLabels,
      checklistNameContains: '타인',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ResultSectionHeader(
          title: '이상 프로파일(변화 방향)',
          subtitle: '이상은 “되고 싶은 나”를 통해 변화가 회복 방향인지 도피 방향인지 확인하는 자료입니다.',
        ),
        const SizedBox(height: 12),
        Text(
          '이상 그래프',
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const ScoreLegend(),
        const SizedBox(height: 8),
        InteractiveLineChart(
          selfScores: selfScores,
          otherScores: otherScores,
          selfLabels: selfLabels,
          otherLabels: otherLabels,
        ),
        const SizedBox(height: 16),
        Text(
          '이상 수치(표)',
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        ScoreTable(
          selfLabels: selfLabels,
          selfScores: selfScores,
          otherLabels: otherLabels,
          otherScores: otherScores,
        ),
        const SizedBox(height: 10),
        Text(
          '도피/회복 판정은 아래 “GPT로 추가 설명”에서 문장으로 정리됩니다.',
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

