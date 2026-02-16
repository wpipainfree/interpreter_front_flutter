import 'package:flutter/material.dart';
import '../../app/di/app_scope.dart';
import '../../router/app_routes.dart';
import '../../ui/result/view_models/user_result_detail_view_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../utils/auth_ui.dart';
import '../../utils/strings.dart';
import '../../widgets/app_error_view.dart';
import 'user_result_detail/sections/ideal_profile_section.dart';
import 'user_result_detail/sections/initial_interpretation_section.dart';
import 'user_result_detail/sections/reality_profile_section.dart';
import 'user_result_detail/widgets/result_section_header.dart';

class UserResultDetailScreen extends StatefulWidget {
  const UserResultDetailScreen({
    super.key,
    required this.resultId,
    this.testId,
  });

  final int resultId;
  final int? testId;

  @override
  State<UserResultDetailScreen> createState() => _UserResultDetailScreenState();
}

class _UserResultDetailScreenState extends State<UserResultDetailScreen> {
  late final UserResultDetailViewModel _viewModel;
  final TextEditingController _storyController = TextEditingController();
  String _lastSyncedStory = '';

  @override
  void initState() {
    super.initState();
    _viewModel = UserResultDetailViewModel(
      AppScope.instance.resultRepository,
      resultId: widget.resultId,
      testId: widget.testId,
    );
    _viewModel.addListener(_handleViewModelChanged);
    _viewModel.start();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_handleViewModelChanged);
    _viewModel.dispose();
    _storyController.dispose();
    super.dispose();
  }

  void _handleViewModelChanged() {
    final nextStory = (_viewModel.mindFocus ?? '').trim();
    if (nextStory != _lastSyncedStory) {
      final localStory = _storyController.text.trim();
      final canOverwrite = localStory.isEmpty || localStory == _lastSyncedStory;
      if (canOverwrite && localStory != nextStory) {
        _storyController.value = TextEditingValue(
          text: nextStory,
          selection: TextSelection.collapsed(offset: nextStory.length),
        );
      }
      _lastSyncedStory = nextStory;
    }

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _submitStoryAndGenerate() async {
    final story = _storyController.text.trim();
    if (story.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                '\uc0ac\uc5f0\uc744 \uc785\ub825\ud574 \uc8fc\uc138\uc694.')),
      );
      return;
    }

    await _viewModel.submitStory(story);
  }

  Future<void> _promptLoginAndReload() async {
    final ok = await AuthUi.promptLogin(context: context);
    if (ok && mounted) {
      await _viewModel.reloadAfterLogin();
    }
  }

  void _openPhase3({String? initialPrompt}) {
    final realityResultId = _viewModel.realityDetail?.result.id;
    if (realityResultId == null) return;

    final sessionId = _viewModel.initialSessionId;
    if (sessionId.isEmpty) return;

    final idealResultId = _viewModel.idealDetail?.result.id;
    final mindFocus = (_viewModel.mindFocus ?? '').trim();
    Navigator.of(context).pushNamed(
      AppRoutes.interpretation,
      arguments: InterpretationArgs(
        initialRealityResultId: realityResultId,
        initialIdealResultId: idealResultId,
        mindFocus: mindFocus.isNotEmpty ? mindFocus : null,
        initialSessionId: sessionId,
        initialTurn: _viewModel.nextTurn,
        initialPrompt: initialPrompt,
        startInPhase3: true,
      ),
    );
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
    if (_viewModel.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_viewModel.error != null) {
      final loggedIn = _viewModel.isLoggedIn;
      return AppErrorView(
        title: loggedIn ? '불러오지 못했어요' : '로그인이 필요합니다',
        message: _viewModel.error!,
        primaryActionLabel: loggedIn ? AppStrings.retry : AppStrings.login,
        primaryActionStyle: loggedIn
            ? AppErrorPrimaryActionStyle.outlined
            : AppErrorPrimaryActionStyle.filled,
        onPrimaryAction:
            loggedIn ? () => _viewModel.load() : () => _promptLoginAndReload(),
      );
    }

    final reality = _viewModel.realityDetail;
    final ideal = _viewModel.idealDetail;
    if (reality == null && ideal == null) {
      return Center(
        child: Text(AppStrings.resultDetailLoadFail,
            style: AppTextStyles.bodyMedium),
      );
    }

    final headerDate = _formatDateTime((reality ?? ideal)!.result.createdAt);

    const selfKeyLabels = [
      'Realist',
      'Romanticist',
      'Humanist',
      'Idealist',
      'Agent'
    ];
    const otherKeyLabels = ['Relation', 'Trust', 'Manual', 'Self', 'Culture'];
    const selfDisplayLabels = ['리얼리스트', '로맨티스트', '휴머니스트', '아이디얼리스트', '에이전트'];
    const otherDisplayLabels = ['릴레이션', '트러스트', '매뉴얼', '셀프', '컬처'];

    final storyForAi = (reality != null) ? (_viewModel.mindFocus ?? '') : '';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _topHeader(date: headerDate, mindFocus: _viewModel.mindFocus),
          const SizedBox(height: 20),
          RealityProfileSection(
            detail: reality,
            selfLabels: selfKeyLabels,
            otherLabels: otherKeyLabels,
            selfDisplayLabels: selfDisplayLabels,
            otherDisplayLabels: otherDisplayLabels,
          ),
          const SizedBox(height: 24),
          IdealProfileSection(
            detail: ideal,
            selfLabels: selfKeyLabels,
            otherLabels: otherKeyLabels,
            selfDisplayLabels: selfDisplayLabels,
            otherDisplayLabels: otherDisplayLabels,
          ),
          const SizedBox(height: 24),
          if (reality != null && storyForAi.trim().isEmpty) ...[
            const ResultSectionHeader(
              title: '마음 해석하기',
              subtitle: '당신의 고민을 입력해주세요. WPI 프로파일 바탕으로 당신의 마음 구조를 분석합니다.',
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '사연 입력',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _storyController,
                    minLines: 2,
                    maxLines: 4,
                    maxLength: 200,
                    decoration: const InputDecoration(
                      hintText: '예) 요즘 쉽게 예민해져요. 왜 그런지 알고 싶어요.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _viewModel.initialState ==
                              InitialInterpretationLoadState.loading
                          ? null
                          : _submitStoryAndGenerate,
                      child: const Text('자동 해석 생성'),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            InitialInterpretationSection(
              story: storyForAi,
              state: _viewModel.initialState,
              response: _viewModel.initialInterpretation,
              errorMessage: _viewModel.initialError,
              canOpenPhase3: _viewModel.canOpenPhase3,
              onRetry: _viewModel.retryInitialInterpretation,
              onOpenPhase3: _openPhase3,
            ),
          ],
        ],
      ),
    );
  }

  Widget _topHeader({required String date, String? mindFocus}) {
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

  String _formatDateTime(DateTime? date) {
    if (date == null) return '-';
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
