import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/psych_tests_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../utils/auth_ui.dart';
import '../../utils/strings.dart';
import '../../widgets/app_error_view.dart';
import 'user_result_detail/profile_helpers.dart';
import 'user_result_detail/sections/ideal_profile_section.dart';
import 'user_result_detail/sections/reality_profile_section.dart';
import 'user_result_detail/widgets/atom_header_card.dart';
import 'user_result_detail/widgets/result_section_header.dart';
import 'user_result_detail/widgets/result_summary_info_card.dart';

class UserResultSingleScreen extends StatefulWidget {
  const UserResultSingleScreen({
    super.key,
    required this.resultId,
    this.testId,
  });

  final int resultId;
  final int? testId;

  @override
  State<UserResultSingleScreen> createState() => _UserResultSingleScreenState();
}

class _UserResultSingleScreenState extends State<UserResultSingleScreen> {
  final AuthService _authService = AuthService();
  final PsychTestsService _testsService = PsychTestsService();

  bool _loading = true;
  String? _error;
  UserResultDetail? _detail;

  late final VoidCallback _authListener;
  bool _lastLoggedIn = false;
  String? _lastUserId;

  static const List<String> _selfKeyLabels = [
    'Realist',
    'Romanticist',
    'Humanist',
    'Idealist',
    'Agent',
  ];
  static const List<String> _otherKeyLabels = [
    'Relation',
    'Trust',
    'Manual',
    'Self',
    'Culture',
  ];
  static const List<String> _selfDisplayLabels = [
    '리얼리스트',
    '로맨티스트',
    '휴머니스트',
    '아이디얼리스트',
    '에이전트',
  ];
  static const List<String> _otherDisplayLabels = [
    '릴레이션',
    '트러스트',
    '매뉴얼',
    '셀프',
    '컬처',
  ];

  @override
  void initState() {
    super.initState();
    _lastLoggedIn = _authService.isLoggedIn;
    _lastUserId = _authService.currentUser?.id;
    _authListener = _handleAuthChanged;
    _authService.addListener(_authListener);
    _load();
  }

  @override
  void dispose() {
    _authService.removeListener(_authListener);
    super.dispose();
  }

  void _handleAuthChanged() {
    if (!mounted) return;

    final nowLoggedIn = _authService.isLoggedIn;
    final nowUserId = _authService.currentUser?.id;
    if (nowLoggedIn == _lastLoggedIn && nowUserId == _lastUserId) return;

    _lastLoggedIn = nowLoggedIn;
    _lastUserId = nowUserId;

    if (nowLoggedIn) {
      _load();
      return;
    }

    setState(() {
      _detail = null;
      _loading = false;
      _error = AppStrings.loginRequired;
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    if (!_authService.isLoggedIn) {
      setState(() {
        _detail = null;
        _loading = false;
        _error = AppStrings.loginRequired;
      });
      return;
    }

    try {
      final detail = await _testsService.fetchResultDetail(widget.resultId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      } else {
        _loading = false;
      }
    }
  }

  Future<void> _promptLoginAndReload() async {
    final ok = await AuthUi.promptLogin(context: context);
    if (ok && mounted) {
      await _load();
    }
  }

  bool _isIdeal(UserResultDetail detail) {
    final testId = widget.testId ?? detail.result.testId;
    return testId == 3;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(AppStrings.resultDetailTitle, style: AppTextStyles.h4),
        backgroundColor: AppColors.backgroundLight,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      final loggedIn = _authService.isLoggedIn;
      return AppErrorView(
        title: loggedIn ? '불러오지 못했어요' : '로그인이 필요합니다',
        message: _error!,
        primaryActionLabel: loggedIn ? AppStrings.retry : AppStrings.login,
        primaryActionStyle: loggedIn
            ? AppErrorPrimaryActionStyle.outlined
            : AppErrorPrimaryActionStyle.filled,
        onPrimaryAction:
            loggedIn ? () => _load() : () => _promptLoginAndReload(),
      );
    }

    final detail = _detail;
    if (detail == null) {
      return Center(
        child: Text(
          AppStrings.resultDetailLoadFail,
          style: AppTextStyles.bodyMedium,
        ),
      );
    }

    final isIdeal = _isIdeal(detail);
    final headerDate = _formatDateTime(detail.result.createdAt);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _topHeader(date: headerDate),
          const SizedBox(height: 20),
          if (isIdeal) ...[
            _buildAtomSection(detail),
            const SizedBox(height: 24),
            IdealProfileSection(
              detail: detail,
              selfLabels: _selfKeyLabels,
              otherLabels: _otherKeyLabels,
              selfDisplayLabels: _selfDisplayLabels,
              otherDisplayLabels: _otherDisplayLabels,
            ),
          ] else ...[
            RealityProfileSection(
              detail: detail,
              selfLabels: _selfKeyLabels,
              otherLabels: _otherKeyLabels,
              selfDisplayLabels: _selfDisplayLabels,
              otherDisplayLabels: _otherDisplayLabels,
            ),
          ],
        ],
      ),
    );
  }

  Widget _topHeader({required String date}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            date,
            style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildAtomSection(UserResultDetail detail) {
    final selfScores = extractScores(
      detail.classes,
      _selfKeyLabels,
      checklistNameContains: '자기',
    );
    final otherScores = extractScores(
      detail.classes,
      _otherKeyLabels,
      checklistNameContains: '타인',
    );

    final atomType = _resolvePrimaryType(_selfKeyLabels, selfScores);
    final atomState = _resolveAtomState(atomType, selfScores, otherScores);
    final atomAsset = _atomAssetPath(atomType, atomState);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ResultSectionHeader(
          title: '마음의 원자 구조',
          subtitle: '내 마음을 한눈에 파악할 수 있어요.',
        ),
        const SizedBox(height: 12),
        AtomHeaderCard(
          typeLabel: _atomTypeLabel(atomType),
          stateLabel: _atomStateLabel(atomState),
          assetPath: atomAsset,
        ),
        const SizedBox(height: 12),
        ResultSummaryInfoCard(
          title: '기준과 믿음의 기울기',
          body: _gapSummaryText(atomState),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return '-';
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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
        return '기준이 믿음을 누르며 ‘해야 한다’가 먼저 서는 상태였어요.';
      case AtomState.over:
        return '믿음이 기준을 앞질러 ‘내 방식대로’가 먼저 나오는 상태였어요.';
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

enum AtomType { realist, romanticist, humanist, idealist, agent }

enum AtomState { base, over, under }

const double _stateGapThreshold = 10.0;
const String _atomAssetBasePath = 'assets/images/wpi_atom';
