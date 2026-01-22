import 'package:flutter/material.dart';

import '../../../../services/psych_tests_service.dart';
import '../profile_helpers.dart';
import '../widgets/atom_header_card.dart';
import '../widgets/interactive_line_chart.dart';
import '../widgets/result_section_header.dart';
import '../widgets/result_summary_info_card.dart';
import '../widgets/score_legend.dart';
import '../widgets/score_table.dart';

enum AtomType { realist, romanticist, humanist, idealist, agent }

enum AtomState { base, over, under }

const double _stateGapThreshold = 10.0;
const String _atomAssetBasePath = 'assets/images/wpi_atom';

class RealityProfileSection extends StatelessWidget {
  const RealityProfileSection({
    super.key,
    required this.detail,
    required this.selfLabels,
    required this.otherLabels,
    this.selfDisplayLabels,
    this.otherDisplayLabels,
  });

  final UserResultDetail? detail;
  final List<String> selfLabels;
  final List<String> otherLabels;
  final List<String>? selfDisplayLabels;
  final List<String>? otherDisplayLabels;

  @override
  Widget build(BuildContext context) {
    final result = detail;
    if (result == null) {
      return const ResultSectionHeader(
        title: '현실 프로파일',
        subtitle: '현실 결과를 찾을 수 없습니다.',
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

    final selfLabelsForUi = selfDisplayLabels ?? selfLabels;
    final otherLabelsForUi = otherDisplayLabels ?? otherLabels;

    final atomType = _resolvePrimaryType(selfLabels, selfScores);
    final atomState = _resolveAtomState(atomType, selfScores, otherScores);
    final atomAsset = _atomAssetPath(atomType, atomState);

    final typeLabel = _atomTypeLabel(atomType);
    final stateLabel = _atomStateLabel(atomState);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ResultSectionHeader(
          title: '현실 프로파일',
          subtitle: '현실은 현재 구조(기준·믿음 기울기)와 붕괴 방향(오버/언더)을 이해하는 영역입니다.',
        ),
        const SizedBox(height: 12),
        AtomHeaderCard(
          typeLabel: typeLabel,
          stateLabel: stateLabel,
          assetPath: atomAsset,
        ),
        const SizedBox(height: 12),
        ResultSummaryInfoCard(
          title: '기준과 믿음의 기울기',
          body: _gapSummaryText(atomState),
        ),
        const SizedBox(height: 8),
        const ResultSummaryInfoCard(
          title: '감정·몸 반응은 구조 신호',
          body: '불안·답답함·긴장·피로는 구조 충돌이 올라오는 신호일 수 있어요.',
        ),
        const SizedBox(height: 16),
        const ResultSectionHeader(
          title: '현실 근거(점수/구조)',
          subtitle: '그래프/표는 위 요약을 뒷받침하는 근거 자료입니다.',
        ),
        const SizedBox(height: 8),
        const ScoreLegend(),
        const SizedBox(height: 8),
        InteractiveLineChart(
          selfScores: selfScores,
          otherScores: otherScores,
          selfLabels: selfLabelsForUi,
          otherLabels: otherLabelsForUi,
        ),
        const SizedBox(height: 12),
        ScoreTable(
          selfLabels: selfLabelsForUi,
          selfScores: selfScores,
          otherLabels: otherLabelsForUi,
          otherScores: otherScores,
        ),
      ],
    );
  }

  AtomType _resolvePrimaryType(List<String> labels, List<double?> scores) {
    var maxScore = -1.0;
    String? maxLabel;
    for (var i = 0; i < labels.length; i++) {
      final value = scores[i];
      if (value != null && value > maxScore) {
        maxScore = value;
        maxLabel = labels[i];
      }
    }
    return _typeFromLabel(maxLabel ?? '') ?? AtomType.realist;
  }

  AtomState _resolveAtomState(
    AtomType atomType,
    List<double?> selfScores,
    List<double?> otherScores,
  ) {
    final index = _atomTypeIndex(atomType);
    if (index < 0 || index >= selfScores.length || index >= otherScores.length) {
      return AtomState.base;
    }

    final selfScore = selfScores[index];
    final otherScore = otherScores[index];
    if (selfScore == null || otherScore == null) return AtomState.base;

    final gap = selfScore - otherScore;
    if (gap > _stateGapThreshold) return AtomState.over;
    if (gap <= -_stateGapThreshold) return AtomState.under;
    return AtomState.base;
  }

  int _atomTypeIndex(AtomType type) {
    // Index mapping: Realist/Relation, Romanticist/Trust, Humanist/Manual, Idealist/Self, Agent/Culture.
    switch (type) {
      case AtomType.realist:
        return 0;
      case AtomType.romanticist:
        return 1;
      case AtomType.humanist:
        return 2;
      case AtomType.idealist:
        return 3;
      case AtomType.agent:
        return 4;
    }
  }

  AtomType? _typeFromLabel(String raw) {
    if (raw.isEmpty) return null;
    final normalized = _normalize(raw);
    switch (normalized) {
      case 'realist':
        return AtomType.realist;
      case 'romanticist':
        return AtomType.romanticist;
      case 'humanist':
        return AtomType.humanist;
      case 'idealist':
        return AtomType.idealist;
      case 'agent':
        return AtomType.agent;
    }
    return null;
  }

  String _normalize(String raw) {
    final normalized = raw.toLowerCase().replaceAll(' ', '').split('/').first;
    if (normalized == 'romantist') return 'romanticist';
    return normalized;
  }

  String _atomTypeLabel(AtomType type) {
    switch (type) {
      case AtomType.realist:
        return '리얼리스트';
      case AtomType.romanticist:
        return '로맨티스트';
      case AtomType.humanist:
        return '휴머니스트';
      case AtomType.idealist:
        return '아이디얼리스트';
      case AtomType.agent:
        return '에이전트';
    }
  }

  String _atomStateLabel(AtomState state) {
    switch (state) {
      case AtomState.base:
        return '균형';
      case AtomState.over:
        return '오버슈팅';
      case AtomState.under:
        return '언더슈팅';
    }
  }

  String _gapSummaryText(AtomState state) {
    switch (state) {
      case AtomState.under:
        return '기준이 믿음을 누르며 ‘해야 한다’가 먼저 서는 상태예요.';
      case AtomState.over:
        return '믿음이 기준을 앞질러 ‘내 방식대로’가 먼저 나오는 상태예요.';
      case AtomState.base:
        return '기준과 믿음의 간격이 크지 않아, 균형을 유지하기 쉬운 편이에요.';
    }
  }

  String _atomAssetPath(AtomType type, AtomState state) {
    final typeKey = switch (type) {
      AtomType.realist => 'realist',
      AtomType.romanticist => 'romanticist',
      AtomType.humanist => 'humanist',
      AtomType.idealist => 'idealist',
      AtomType.agent => 'agent',
    };
    final stateKey = switch (state) {
      AtomState.base => 'base',
      AtomState.over => 'over',
      AtomState.under => 'under',
    };
    return '$_atomAssetBasePath/${typeKey}_$stateKey.jpg';
  }
}
