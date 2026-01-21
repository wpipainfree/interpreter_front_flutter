import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/openai_interpret_response.dart';
import '../../services/auth_service.dart';
import '../../services/psych_tests_service.dart';
import '../../services/user_result_detail_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../utils/auth_ui.dart';
import '../../utils/strings.dart';
import '../mymind/interpretation_screen.dart';
import 'user_result_detail/sections/ideal_profile_section.dart';
import 'user_result_detail/sections/initial_interpretation_section.dart';
import 'user_result_detail/sections/reality_profile_section.dart';

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

      setState(() {
        _mindFocus = bundle.mindFocus;
        _realityDetail = bundle.reality;
        _idealDetail = bundle.ideal;
      });

      unawaited(
        _loadInitialInterpretation(
          reality: bundle.reality,
          ideal: bundle.ideal,
          mindFocus: bundle.mindFocus,
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InterpretationScreen(
          initialRealityResultId: realityResultId,
          initialIdealResultId: idealResultId,
          mindFocus: mindFocus.isNotEmpty ? mindFocus : null,
          initialSessionId: sessionId,
          initialTurn: _nextTurn(_initialInterpretation),
          initialPrompt: initialPrompt,
          startInPhase3: true,
        ),
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
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: AppTextStyles.bodyMedium),
            const SizedBox(height: 12),
            if (!_authService.isLoggedIn) ...[
              ElevatedButton(
                onPressed: _promptLoginAndReload,
                child: const Text(AppStrings.login),
              ),
              const SizedBox(height: 12),
            ],
            ElevatedButton(
              onPressed: _load,
              child: const Text(AppStrings.retry),
            ),
          ],
        ),
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

    const selfLabels = [
      'Realist',
      'Romanticist',
      'Humanist',
      'Idealist',
      'Agent'
    ];
    const otherLabels = ['Relation', 'Trust', 'Manual', 'Self', 'Culture'];

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
            selfLabels: selfLabels,
            otherLabels: otherLabels,
          ),
          const SizedBox(height: 24),
          IdealProfileSection(
            detail: ideal,
            selfLabels: selfLabels,
            otherLabels: otherLabels,
          ),
          const SizedBox(height: 24),
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
          if (trimmedFocus.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '내가 알고 싶은 마음: $trimmedFocus',
              style: AppTextStyles.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 10),
          Text(
            AppStrings.resultDetailPurposeText,
            style: AppTextStyles.bodySmall,
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
