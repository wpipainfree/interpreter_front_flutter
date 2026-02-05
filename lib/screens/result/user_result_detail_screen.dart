import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/openai_interpret_response.dart';
import '../../router/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/psych_tests_service.dart';
import '../../services/user_result_detail_service.dart';
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
  final AuthService _authService = AuthService();
  final UserResultDetailService _detailService = UserResultDetailService();
  final TextEditingController _storyController = TextEditingController();

  bool _loading = true;
  String? _error;
  UserResultDetail? _realityDetail;
  UserResultDetail? _idealDetail;
  String? _mindFocus;

  InitialInterpretationState _initialState = InitialInterpretationState.idle;
  OpenAIInterpretResponse? _initialInterpretation;
  String? _initialError;

  late final VoidCallback _authListener;
  bool _lastLoggedIn = false;
  String? _lastUserId;

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
    _storyController.dispose();
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
      _realityDetail = null;
      _idealDetail = null;
      _mindFocus = null;
      _initialState = InitialInterpretationState.idle;
      _initialInterpretation = null;
      _initialError = null;
      _loading = false;
      _error = AppStrings.loginRequired;
    });
    _storyController.clear();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final bundle = await _detailService.loadBundle(
        resultId: widget.resultId,
        testId: widget.testId,
      );
      if (!mounted) return;

      final storyOwnerId = bundle.reality?.result.id ?? bundle.ideal?.result.id;
      final resultStory = (bundle.mindFocus ?? '').trim();
      final storedStory = (resultStory.isEmpty && storyOwnerId != null)
          ? ((await _loadStoryOverride(storyOwnerId)) ?? '')
          : '';
      final effectiveStory = resultStory.isNotEmpty ? resultStory : storedStory;

      setState(() {
        _mindFocus = effectiveStory.isEmpty ? null : effectiveStory;
        _realityDetail = bundle.reality;
        _idealDetail = bundle.ideal;
      });
      _storyController.text = effectiveStory;

      unawaited(
        _loadInitialInterpretation(
          reality: bundle.reality,
          ideal: bundle.ideal,
          mindFocus: effectiveStory.isEmpty ? null : effectiveStory,
        ),
      );
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

  String _storyOverrideKey(int resultId) => 'result.story.$resultId';

  Future<String?> _loadStoryOverride(int resultId) async {
    if (resultId <= 0) return null;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storyOverrideKey(resultId));
    final trimmed = (raw ?? '').trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _saveStoryOverride(int resultId, String story) async {
    if (resultId <= 0) return;
    final trimmed = story.trim();
    if (trimmed.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storyOverrideKey(resultId), trimmed);
  }

  Future<void> _submitStoryAndGenerate({
    required UserResultDetail reality,
    required UserResultDetail? ideal,
  }) async {
    final story = _storyController.text.trim();
    if (story.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사연을 입력해 주세요.')),
      );
      return;
    }

    await _saveStoryOverride(reality.result.id, story);
    if (!mounted) return;

    setState(() => _mindFocus = story);

    await _loadInitialInterpretation(
      reality: reality,
      ideal: ideal,
      mindFocus: story,
      force: false,
    );
  }

  Future<void> _loadInitialInterpretation({
    required UserResultDetail? reality,
    required UserResultDetail? ideal,
    required String? mindFocus,
    bool force = false,
  }) async {
    final story = (mindFocus ?? '').trim();
    final realityDetail = reality;

    if (story.isEmpty || realityDetail == null) {
      if (!mounted) return;
      setState(() {
        _initialState = InitialInterpretationState.idle;
        _initialInterpretation = null;
        _initialError = null;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _initialState = InitialInterpretationState.loading;
      _initialInterpretation = null;
      _initialError = null;
    });

    try {
      final parsed = await _detailService.fetchInitialInterpretation(
        reality: realityDetail,
        ideal: ideal,
        story: story,
        force: force,
      );

      if (!mounted) return;
      setState(() {
        _initialState = InitialInterpretationState.success;
        _initialInterpretation = parsed;
        _initialError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initialState = InitialInterpretationState.error;
        _initialError = _detailService.friendlyAiError(e);
      });
    }
  }

  Future<void> _promptLoginAndReload() async {
    final ok = await AuthUi.promptLogin(context: context);
    if (ok && mounted) {
      await _load();
    }
  }

  int? _nextTurn(OpenAIInterpretResponse? response) {
    final sessionId = (response?.session?.sessionId ?? '').trim();
    if (sessionId.isEmpty) return null;
    final serverTurn = response?.session?.turn;
    if (serverTurn == null) return 2;
    return serverTurn + 1;
  }

  void _openPhase3({String? initialPrompt}) {
    final realityResultId = _realityDetail?.result.id;
    if (realityResultId == null) return;

    final sessionId = (_initialInterpretation?.session?.sessionId ?? '').trim();
    if (sessionId.isEmpty) return;

    final idealResultId = _idealDetail?.result.id;
    final mindFocus = (_mindFocus ?? '').trim();
    Navigator.of(context).pushNamed(
      AppRoutes.interpretation,
      arguments: InterpretationArgs(
        initialRealityResultId: realityResultId,
        initialIdealResultId: idealResultId,
        mindFocus: mindFocus.isNotEmpty ? mindFocus : null,
        initialSessionId: sessionId,
        initialTurn: _nextTurn(_initialInterpretation),
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

    final reality = _realityDetail;
    final ideal = _idealDetail;
    if (reality == null && ideal == null) {
      return Center(
        child: Text(AppStrings.resultDetailLoadFail,
            style: AppTextStyles.bodyMedium),
      );
    }

    final headerDate = _formatDateTime((reality ?? ideal)!.result.createdAt);

    const selfKeyLabels = ['Realist', 'Romanticist', 'Humanist', 'Idealist', 'Agent'];
    const otherKeyLabels = ['Relation', 'Trust', 'Manual', 'Self', 'Culture'];
    const selfDisplayLabels = ['리얼리스트', '로맨티스트', '휴머니스트', '아이디얼리스트', '에이전트'];
    const otherDisplayLabels = ['릴레이션', '트러스트', '매뉴얼', '셀프', '컬처'];

    final storyForAi = (reality != null) ? (_mindFocus ?? '') : '';
    final canOpenPhase3 =
        (_initialInterpretation?.session?.sessionId ?? '').trim().isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _topHeader(date: headerDate, mindFocus: _mindFocus),
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
                      onPressed:
                          _initialState == InitialInterpretationState.loading
                              ? null
                              : () => _submitStoryAndGenerate(
                                    reality: reality,
                                    ideal: ideal,
                                  ),
                      child: const Text('자동 해석 생성'),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            InitialInterpretationSection(
              story: storyForAi,
              state: _initialState,
              response: _initialInterpretation,
              errorMessage: _initialError,
              canOpenPhase3: canOpenPhase3,
              onRetry: () => _loadInitialInterpretation(
                reality: reality,
                ideal: ideal,
                mindFocus: storyForAi,
                force: true,
              ),
              onOpenPhase3: _openPhase3,
            ),
          ],
        ],
      ),
    );
  }

  Widget _topHeader({required String date, String? mindFocus}) {
    final trimmedFocus = (mindFocus ?? '').trim();
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
