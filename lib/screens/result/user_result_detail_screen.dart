import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/initial_interpretation_v1.dart';
import '../../models/openai_interpret_response.dart';
import '../../services/ai_assistant_service.dart';
import '../../services/auth_service.dart';
import '../../services/psych_tests_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../auth/login_screen.dart';
import '../mymind/interpretation_screen.dart';

enum _AtomType { realist, romanticist, humanist, idealist, agent }

enum _AtomState { base, over, under }

enum _InitialInterpretationState { idle, loading, success, error }

const double _stateGapThreshold = 10.0;
const String _atomAssetBasePath = 'assets/images/wpi_atom';

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
  final PsychTestsService _service = PsychTestsService();
  final AiAssistantService _aiService = AiAssistantService();

  bool _loading = true;
  String? _error;
  UserResultDetail? _realityDetail;
  UserResultDetail? _idealDetail;
  String? _mindFocus;
  _InitialInterpretationState _initialState = _InitialInterpretationState.idle;
  OpenAIInterpretResponse? _initialInterpretation;
  String? _initialError;
  String? _initialCacheKey;
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
      _loading = false;
      _error = '로그인이 필요합니다.';
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final mindFocus = await _loadMindFocus();
      final anchor = await _service.fetchResultDetail(widget.resultId);
      if (!mounted) return;

      final anchorTestId = anchor.result.testId ?? widget.testId;
      UserResultDetail? reality;
      UserResultDetail? ideal;

      if (anchorTestId == 3) {
        ideal = anchor;
      } else {
        reality = anchor;
      }

      final pairedResultId = await _findPairedResultId(
        userId: anchor.result.userId,
        anchorResultId: widget.resultId,
        anchorTestId: anchorTestId,
      );
      if (!mounted) return;

      if (pairedResultId != null && pairedResultId != widget.resultId) {
        try {
          final paired = await _service.fetchResultDetail(pairedResultId);
          if (!mounted) return;
          final pairedTestId = paired.result.testId;
          if (pairedTestId == 1) {
            reality ??= paired;
          } else if (pairedTestId == 3) {
            ideal ??= paired;
          } else if (anchorTestId == 3) {
            reality ??= paired;
          } else {
            ideal ??= paired;
          }
        } catch (_) {
          // ignore paired result fetch errors
        }
      }

      setState(() {
        _mindFocus = mindFocus;
        _realityDetail = reality;
        _idealDetail = ideal;
      });
      _maybeLoadInitialInterpretation(
        reality: reality,
        ideal: ideal,
        mindFocus: mindFocus,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<String?> _loadMindFocus() async {
    final prefs = await SharedPreferences.getInstance();
    final text = prefs.getString('last_mind_focus_text')?.trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  Future<int?> _findPairedResultId({
    required int userId,
    required int anchorResultId,
    required int? anchorTestId,
  }) async {
    if (userId <= 0) return null;

    final anchorTid = anchorTestId ?? widget.testId;
    if (anchorTid != 1 && anchorTid != 3) return null;
    final counterpartTestId = anchorTid == 1 ? 3 : 1;

    final items = <UserAccountItem>[];
    UserAccountItem? anchorItem;

    var page = 1;
    var hasNext = true;
    var safety = 0;
    while (hasNext && safety < 50) {
      safety += 1;
      final res = await _service.fetchUserAccounts(
        userId: userId,
        page: page,
        pageSize: 50,
        fetchAll: false,
        testIds: const [1, 3],
      );
      items.addAll(res.items);
      if (anchorItem == null) {
        for (final item in res.items) {
          if (item.resultId == anchorResultId) {
            anchorItem = item;
            break;
          }
        }
      }
      hasNext = res.hasNext;
      page += 1;
    }

    if (anchorItem == null) return null;

    final testRequestId = anchorItem.testRequestId;
    if (testRequestId != null && testRequestId > 0) {
      for (final item in items) {
        if (item.testRequestId == testRequestId &&
            item.testId == counterpartTestId &&
            item.resultId != null) {
          return item.resultId;
        }
      }
    }

    // Fallback: choose the closest created date among the opposite test type.
    final anchorDate = _parseAccountDate(anchorItem);
    if (anchorDate == null) return null;

    UserAccountItem? best;
    Duration? bestDiff;
    for (final item in items) {
      if (item.testId != counterpartTestId || item.resultId == null) continue;
      final d = _parseAccountDate(item);
      if (d == null) continue;
      final diff = d.difference(anchorDate).abs();
      if (best == null || diff < (bestDiff ?? diff)) {
        best = item;
        bestDiff = diff;
      }
    }

    if (best != null &&
        (bestDiff ?? const Duration(days: 9999)) <= const Duration(days: 3)) {
      return best.resultId;
    }
    return null;
  }

  DateTime? _parseAccountDate(UserAccountItem item) {
    final raw = item.createDate ?? item.paymentDate ?? item.modifyDate;
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> _promptLoginAndReload() async {
    final ok = await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const LoginScreen(),
      ),
    );
    if (ok == true && mounted) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('내 결과(현실 + 이상)', style: AppTextStyles.h4),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('로그인하기'),
              ),
              const SizedBox(height: 12),
            ],
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    final reality = _realityDetail;
    final ideal = _idealDetail;
    if (reality == null && ideal == null) {
      return Center(
        child: Text('결과를 불러올 수 없습니다.', style: AppTextStyles.bodyMedium),
      );
    }

    final headerDate = _formatDateTime((reality ?? ideal)!.result.createdAt);

    const selfLabels = ['Realist', 'Romanticist', 'Humanist', 'Idealist', 'Agent'];
    const otherLabels = ['Relation', 'Trust', 'Manual', 'Self', 'Culture'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _topHeader(date: headerDate, mindFocus: _mindFocus),
          const SizedBox(height: 20),
          _buildRealityProfileSection(
            detail: reality,
            selfLabels: selfLabels,
            otherLabels: otherLabels,
          ),
          const SizedBox(height: 24),
          _buildIdealProfileSection(
            detail: ideal,
            selfLabels: selfLabels,
            otherLabels: otherLabels,
          ),
          const SizedBox(height: 24),
          _buildInitialInterpretationSection(
            reality: reality,
            ideal: ideal,
            mindFocus: _mindFocus,
          ),
        ],
      ),
    );
  }

  static const String _resultPurposeText =
      '상단 1스크린에서 현실 구조(기준·믿음 기울기)와 현재 붕괴 방향(오버/언더)을 이해시키고, 이상은 변화 방향(도피/회복)을 보는 자료로만 제공한다.';

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
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
          if (trimmedFocus.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '내가 알고 싶은 마음: $trimmedFocus',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 10),
          Text(
            _resultPurposeText,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildRealityProfileSection({
    required UserResultDetail? detail,
    required List<String> selfLabels,
    required List<String> otherLabels,
  }) {
    if (detail == null) {
      return _sectionHeader(
        title: '현실 프로파일',
        subtitle: '현실 결과를 찾을 수 없습니다.',
      );
    }

    final selfScores = _extractScores(
      detail.classes,
      selfLabels,
      checklistNameContains: '자기',
    );
    final otherScores = _extractScores(
      detail.classes,
      otherLabels,
      checklistNameContains: '타인',
    );

    final atomType = _resolvePrimaryType(selfLabels, selfScores);
    final atomState = _resolveAtomState(atomType, selfScores, otherScores);
    final atomAsset = _atomAssetPath(atomType, atomState);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          title: '현실 프로파일',
          subtitle: '현실은 현재 구조(기준·믿음 기울기)와 붕괴 방향(오버/언더)을 이해하는 영역입니다.',
        ),
        const SizedBox(height: 12),
        _atomHeader(atomType: atomType, state: atomState, assetPath: atomAsset),
        const SizedBox(height: 12),
        _summaryInfoCard(
          title: '기준과 믿음의 기울기',
          body: _gapSummaryText(atomState),
        ),
        const SizedBox(height: 8),
        _summaryInfoCard(
          title: '감정·몸 반응은 구조 신호',
          body: _signalSummaryText(atomState),
        ),
        const SizedBox(height: 16),
        _sectionHeader(
          title: '현실 근거(점수/구조)',
          subtitle: '그래프/표는 위 요약을 뒷받침하는 근거 자료입니다.',
        ),
        const SizedBox(height: 8),
        _legend(),
        const SizedBox(height: 8),
        _interactiveLineChart(selfScores, otherScores, selfLabels, otherLabels),
        const SizedBox(height: 12),
        _scoreTable(selfLabels, selfScores, otherLabels, otherScores),
      ],
    );
  }

  Widget _buildIdealProfileSection({
    required UserResultDetail? detail,
    required List<String> selfLabels,
    required List<String> otherLabels,
  }) {
    if (detail == null) {
      return _sectionHeader(
        title: '이상 프로파일(변화 방향)',
        subtitle: '이상 결과가 없습니다.',
      );
    }

    final selfScores = _extractScores(
      detail.classes,
      selfLabels,
      checklistNameContains: '자기',
    );
    final otherScores = _extractScores(
      detail.classes,
      otherLabels,
      checklistNameContains: '타인',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          title: '이상 프로파일(변화 방향)',
          subtitle: '이상은 “되고 싶은 나”를 통해 변화가 회복 방향인지 도피 방향인지 확인하는 자료입니다.',
        ),
        const SizedBox(height: 12),
        Text(
          '이상 그래프',
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        _legend(),
        const SizedBox(height: 8),
        _interactiveLineChart(selfScores, otherScores, selfLabels, otherLabels),
        const SizedBox(height: 16),
        Text(
          '이상 수치(표)',
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        _scoreTable(selfLabels, selfScores, otherLabels, otherScores),
        const SizedBox(height: 10),
        Text(
          '도피/회복 판정은 아래 “GPT로 추가 설명”에서 문장으로 정리됩니다.',
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  static const List<String> _profileSelfKeys = [
    'realist',
    'romantic',
    'humanist',
    'idealist',
    'agent',
  ];
  static const List<String> _profileStandardKeys = [
    'relation',
    'trust',
    'manual',
    'self',
    'culture',
  ];

  Future<void> _maybeLoadInitialInterpretation({
    required UserResultDetail? reality,
    required UserResultDetail? ideal,
    required String? mindFocus,
    bool force = false,
  }) async {
    final story = (mindFocus ?? '').trim();
    final realityId = reality?.result.id;
    if (story.isEmpty || reality == null || realityId == null) {
      if (!mounted) return;
      setState(() {
        _initialState = _InitialInterpretationState.idle;
        _initialInterpretation = null;
        _initialError = null;
        _initialCacheKey = null;
      });
      return;
    }

    final key = _initialInterpretationKey(
      resultId: realityId,
      story: story,
    );

    if (!force && _initialCacheKey == key) {
      if (_initialState == _InitialInterpretationState.loading ||
          _initialState == _InitialInterpretationState.success) {
        return;
      }
    }

    _initialCacheKey = key;

    final prefs = await SharedPreferences.getInstance();
    final cachedRaw = prefs.getString(key);
    if (!force && cachedRaw != null && cachedRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(cachedRaw);
        if (decoded is Map<String, dynamic>) {
          final parsed = OpenAIInterpretResponse.fromJson(decoded);
          if (!mounted) return;
          setState(() {
            _initialState = _InitialInterpretationState.success;
            _initialInterpretation = parsed;
            _initialError = null;
          });
          return;
        }
      } catch (_) {
        // ignore cache parsing errors; fall through to refetch
      }
    }

    if (!mounted) return;
    setState(() {
      _initialState = _InitialInterpretationState.loading;
      _initialInterpretation = null;
      _initialError = null;
    });

    try {
      final payload = _buildPhase2CardsPayload(
        reality: reality,
        ideal: ideal,
        story: story,
      );
      final raw = await _aiService.interpret(payload);
      final toCache = <String, dynamic>{
        'session': raw['session'],
        'interpretation': raw['interpretation'],
      };
      final parsed = OpenAIInterpretResponse.fromJson(toCache);
      await prefs.setString(key, jsonEncode(toCache));

      if (!mounted) return;
      setState(() {
        _initialState = _InitialInterpretationState.success;
        _initialInterpretation = parsed;
        _initialError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initialState = _InitialInterpretationState.error;
        _initialError = _friendlyAiError(e);
      });
    }
  }

  Map<String, dynamic> _buildPhase2CardsPayload({
    required UserResultDetail reality,
    required UserResultDetail? ideal,
    required String story,
  }) {
    final realityProfile = _buildProfileJson(reality);
    final idealProfile = ideal != null ? _buildProfileJson(ideal) : _emptyProfileJson();
    return <String, dynamic>{
      'session': <String, dynamic>{
        'session_id': null,
        'turn': 1,
      },
      'phase': 2,
      'profiles': <String, dynamic>{
        'reality': realityProfile,
        'ideal': idealProfile,
      },
      'model': 'gpt-5.2',
      'story': <String, dynamic>{'content': story},
      'output_format': 'cards_v1',
    };
  }

  Map<String, dynamic> _buildProfileJson(UserResultDetail detail) {
    final selfScores = <String, double>{};
    final standardScores = <String, double>{};
    for (final item in detail.classes) {
      final name = item.name ?? '';
      if (name.isEmpty) continue;
      final key = _normalizeProfileKey(name);
      final value = item.point ?? 0;
      final checklist = item.checklistName ?? '';
      if (_profileSelfKeys.contains(key)) {
        if (checklist.contains('자기평가') || !_profileStandardKeys.contains(key)) {
          selfScores[key] = value;
        }
        continue;
      }
      if (_profileStandardKeys.contains(key)) {
        if (checklist.contains('타인평가') || !_profileSelfKeys.contains(key)) {
          standardScores[key] = value;
        }
      }
    }
    return <String, dynamic>{
      'self_scores': {for (final key in _profileSelfKeys) key: selfScores[key] ?? 0},
      'standard_scores': {
        for (final key in _profileStandardKeys) key: standardScores[key] ?? 0
      },
    };
  }

  Map<String, dynamic> _emptyProfileJson() => <String, dynamic>{
        'self_scores': {for (final key in _profileSelfKeys) key: 0},
        'standard_scores': {for (final key in _profileStandardKeys) key: 0},
      };

  String _normalizeProfileKey(String raw) {
    final normalized = raw.toLowerCase().replaceAll(' ', '').split('/').first;
    if (normalized == 'romantist' || normalized == 'romanticist') return 'romantic';
    return normalized;
  }

  String _initialInterpretationKey({
    required int resultId,
    required String story,
  }) {
    final hash = _fnv1a32Hex(story);
    return 'ai.initial_interpretation.cards_v1.$resultId.$hash';
  }

  String _fnv1a32Hex(String input) {
    const int fnvPrime = 0x01000193;
    const int fnvOffsetBasis = 0x811C9DC5;
    var hash = fnvOffsetBasis;
    for (final unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * fnvPrime) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  String _friendlyAiError(Object error) {
    if (error is AuthRequiredException) {
      return '로그인이 만료되었어요. 다시 로그인해 주세요.';
    }
    if (error is AiAssistantHttpException) {
      switch (error.statusCode) {
        case 400:
          return '요청 형식이 올바르지 않습니다. 잠시 후 다시 시도해 주세요.';
        case 401:
          return '로그인이 만료되었어요. 다시 로그인해 주세요.';
        case 429:
          return '요청이 많아 잠시 후 다시 시도해 주세요.';
        case 503:
        case 504:
          return '서버가 혼잡해요. 잠시 후 다시 시도해 주세요.';
      }
      return error.message;
    }
    return error.toString();
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

  Widget _buildInitialInterpretationSection({
    required UserResultDetail? reality,
    required UserResultDetail? ideal,
    required String? mindFocus,
  }) {
    final story = (mindFocus ?? '').trim();
    if (story.isEmpty || reality == null) {
      return _sectionHeader(
        title: '자동 해석',
        subtitle: '“알고 싶은 마음(사연)”이 있을 때만 자동으로 생성됩니다.',
      );
    }

    final interpretation = _initialInterpretation?.interpretation;
    final viewModel = interpretation?.viewModel;
    final fallbackText = (interpretation?.response ?? '').trim();

    final isParseProblem =
        interpretation != null && interpretation.viewModelMalformed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          title: '자동 해석',
          subtitle: '결과 + 사연을 바탕으로 1문장 요약과 카드를 생성합니다.',
        ),
        const SizedBox(height: 12),
        if (_initialState == _InitialInterpretationState.loading) ...[
          _loadingCard(),
        ] else if (_initialState == _InitialInterpretationState.error) ...[
          _errorCard(
            message: _initialError ?? '자동 해석을 불러오지 못했습니다.',
            onRetry: () => _maybeLoadInitialInterpretation(
              reality: reality,
              ideal: ideal,
              mindFocus: mindFocus,
              force: true,
            ),
          ),
        ] else if (viewModel != null && viewModel.cards.isNotEmpty) ...[
          _headlineCard(viewModel.headline),
          const SizedBox(height: 12),
          ...viewModel.cards.map(_interpretationCard),
          const SizedBox(height: 12),
          _ctaAndSuggestions(
            viewModel: viewModel,
            onCta: _openPhase3,
          ),
        ] else if (fallbackText.isNotEmpty) ...[
          if (isParseProblem)
            _subtleWarning(
              '카드형 해석을 표시하지 못했어요. 텍스트로 보여드릴게요.',
            ),
          _markdownCard(fallbackText),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => _maybeLoadInitialInterpretation(
              reality: reality,
              ideal: ideal,
              mindFocus: mindFocus,
              force: true,
            ),
            child: const Text('다시 시도'),
          ),
        ] else ...[
          _errorCard(
            message: '자동 해석 결과가 비어있습니다.',
            onRetry: () => _maybeLoadInitialInterpretation(
              reality: reality,
              ideal: ideal,
              mindFocus: mindFocus,
              force: true,
            ),
          ),
        ],
      ],
    );
  }

  Widget _loadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Text('자동 해석을 불러오는 중…', style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }

  Widget _errorCard({
    required String message,
    required VoidCallback onRetry,
  }) {
    return Container(
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
          Text('자동 해석을 불러오지 못했습니다.', style: AppTextStyles.h5),
          const SizedBox(height: 8),
          Text(
            message,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  Widget _subtleWarning(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
      ),
    );
  }

  Widget _headlineCard(String headline) {
    final trimmed = headline.trim();
    if (trimmed.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        trimmed,
        style: AppTextStyles.h5.copyWith(color: AppColors.textPrimary),
      ),
    );
  }

  Widget _interpretationCard(InitialInterpretationCard card) {
    final bullets = card.bullets;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
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
            card.title,
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            card.summary,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          if (bullets.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...bullets.map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  '),
                    Expanded(
                      child: Text(
                        b,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if ((card.checkQuestion ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '체크 질문: ${card.checkQuestion}',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _ctaAndSuggestions({
    required InitialInterpretationV1 viewModel,
    required void Function({String? initialPrompt}) onCta,
  }) {
    final label = viewModel.next.ctaLabel.trim().isNotEmpty
        ? viewModel.next.ctaLabel.trim()
        : '내 마음 더 알아보기';
    final prompts = viewModel.suggestedPrompts;
    final canOpen = (_initialInterpretation?.session?.sessionId ?? '').trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: canOpen ? () => onCta() : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
            ),
            child: Text(label),
          ),
        ),
        if (prompts.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text('추천 질문', style: AppTextStyles.caption),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: prompts
                .map(
                  (p) => ActionChip(
                    label: Text(p),
                    onPressed: canOpen ? () => onCta(initialPrompt: p) : null,
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _markdownCard(String markdown) {
    final baseTextStyle = AppTextStyles.bodySmall.copyWith(
      color: AppColors.textSecondary,
      height: 1.55,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: MarkdownBody(
        data: markdown,
        styleSheet: MarkdownStyleSheet(
          p: baseTextStyle,
          h1: baseTextStyle.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
          h2: baseTextStyle.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
          h3: baseTextStyle.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
          strong: baseTextStyle.copyWith(fontWeight: FontWeight.w700),
          em: baseTextStyle.copyWith(fontStyle: FontStyle.italic),
          blockquotePadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          blockquoteDecoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          codeblockDecoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          code: baseTextStyle.copyWith(fontFamily: 'monospace', fontSize: 12),
        ),
      ),
    );
  }

  Widget _legend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        _LegendDot(color: Colors.red, label: '자기평가'),
        SizedBox(width: 16),
        _LegendDot(color: Colors.blue, label: '타인평가'),
      ],
    );
  }

  Widget _atomHeader({
    required _AtomType atomType,
    required _AtomState state,
    required String assetPath,
  }) {
    final typeLabel = _atomTypeLabel(atomType);
    final stateLabel = _atomStateLabel(state);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
                        const Icon(Icons.image_outlined, size: 32, color: AppColors.textSecondary),
                        const SizedBox(height: 6),
                        Text(
                          '$typeLabel · $stateLabel',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
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
                    _metaChip('유형: $typeLabel'),
                    _metaChip('핵 기울기: $stateLabel'),
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
        ),
      ],
    );
  }

  Widget _metaChip(String text) {
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

  Widget _summaryInfoCard({required String title, required String body}) {
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
          Text(title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(body, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _sectionHeader({required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.h4),
        const SizedBox(height: 4),
        Text(subtitle, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _interactiveLineChart(
    List<double?> selfScores,
    List<double?> otherScores,
    List<String> selfLabels,
    List<String> otherLabels,
  ) {
    return _LineChartArea(
      selfScores: selfScores,
      otherScores: otherScores,
      selfLabels: selfLabels,
      otherLabels: otherLabels,
      startOffset: _LineChartAreaState._startOffset,
    );
  }

  Widget _scoreTable(
    List<String> selfLabels,
    List<double?> selfScores,
    List<String> otherLabels,
    List<double?> otherScores,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tableSection(
          title: '자기평가',
          titleColor: Colors.red,
          headerBg: const Color(0xFFFFEEF2),
          labels: selfLabels,
          scores: selfScores,
        ),
        const SizedBox(height: 12),
        _tableSection(
          title: '타인평가',
          titleColor: Colors.blue,
          headerBg: const Color(0xFFE8EDFF),
          labels: otherLabels,
          scores: otherScores,
        ),
      ],
    );
  }

  Widget _tableSection({
    required String title,
    required Color titleColor,
    required Color headerBg,
    required List<String> labels,
    required List<double?> scores,
  }) {
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
              inside: BorderSide(color: AppColors.border),
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
                            color: titleColor,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          softWrap: true,
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
                          score != null ? score.toStringAsFixed(1).replaceAll(RegExp(r'\.0\$'), '') : '-',
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
  String _formatDateTime(DateTime? date) {
    if (date == null) return '-';
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  List<double?> _extractScores(
    List<ResultClassItem> items,
    List<String> labels, {
    String? checklistNameContains,
  }) {
    final map = <String, double?>{};
    for (final item in items) {
      final name = _normalize(item.name ?? item.checklistName ?? '');
      if (checklistNameContains != null) {
        final ckName = item.checklistName ?? '';
        if (!ckName.contains(checklistNameContains)) continue;
      }
      final value = item.point;
      if (labels.any((l) => _normalize(l) == name)) {
        map[name] = value;
      }
    }
    return labels
        .map((l) {
          final key = _normalize(l);
          return map[key];
        })
        .toList();
  }

  String _normalize(String raw) {
    final normalized = raw.toLowerCase().replaceAll(' ', '').split('/').first;
    if (normalized == 'romantist') return 'romanticist';
    return normalized;
  }

  _AtomType _resolvePrimaryType(List<String> labels, List<double?> scores) {
    double maxScore = -1;
    String? maxLabel;
    for (var i = 0; i < labels.length; i++) {
      final value = scores[i];
      if (value != null && value > maxScore) {
        maxScore = value;
        maxLabel = labels[i];
      }
    }
    return _typeFromLabel(maxLabel ?? '') ?? _AtomType.realist;
  }

  _AtomState _resolveAtomState(
    _AtomType atomType,
    List<double?> selfScores,
    List<double?> otherScores,
  ) {
    final index = _atomTypeIndex(atomType);
    if (index < 0 || index >= selfScores.length || index >= otherScores.length) {
      return _AtomState.base;
    }

    final selfScore = selfScores[index];
    final otherScore = otherScores[index];
    if (selfScore == null || otherScore == null) return _AtomState.base;

    final gap = selfScore - otherScore;
    if (gap > _stateGapThreshold) return _AtomState.over;
    if (gap <= -_stateGapThreshold) return _AtomState.under;
    return _AtomState.base;
  }

  int _atomTypeIndex(_AtomType type) {
    // Index mapping: Realist/Relation, Romanticist/Trust, Humanist/Manual, Idealist/Self, Agent/Culture.
    switch (type) {
      case _AtomType.realist:
        return 0;
      case _AtomType.romanticist:
        return 1;
      case _AtomType.humanist:
        return 2;
      case _AtomType.idealist:
        return 3;
      case _AtomType.agent:
        return 4;
    }
  }

  _AtomType? _typeFromLabel(String raw) {
    if (raw.isEmpty) return null;
    final normalized = _normalize(raw);
    switch (normalized) {
      case 'realist':
        return _AtomType.realist;
      case 'romanticist':
        return _AtomType.romanticist;
      case 'humanist':
        return _AtomType.humanist;
      case 'idealist':
        return _AtomType.idealist;
      case 'agent':
        return _AtomType.agent;
    }
    return null;
  }

  String _atomTypeLabel(_AtomType type) {
    switch (type) {
      case _AtomType.realist:
        return '리얼리스트';
      case _AtomType.romanticist:
        return '로맨티스트';
      case _AtomType.humanist:
        return '휴머니스트';
      case _AtomType.idealist:
        return '아이디얼리스트';
      case _AtomType.agent:
        return '에이전트';
    }
  }

  String _atomStateLabel(_AtomState state) {
    switch (state) {
      case _AtomState.base:
        return '균형';
      case _AtomState.over:
        return '오버슈팅';
      case _AtomState.under:
        return '언더슈팅';
    }
  }

  String _gapSummaryText(_AtomState state) {
    switch (state) {
      case _AtomState.under:
        return '기준이 믿음을 누르며 ‘해야 한다’가 먼저 서는 상태예요.';
      case _AtomState.over:
        return '믿음이 기준을 앞질러 ‘내 방식대로’가 먼저 나오는 상태예요.';
      case _AtomState.base:
        return '기준과 믿음의 간격이 크지 않아, 균형을 유지하기 쉬운 편이에요.';
    }
  }

  String _signalSummaryText(_AtomState state) {
    return '불안·답답함·긴장·피로는 구조 충돌이 올라오는 신호일 수 있어요.';
  }

  String _atomAssetPath(_AtomType type, _AtomState state) {
    final typeKey = switch (type) {
      _AtomType.realist => 'realist',
      _AtomType.romanticist => 'romanticist',
      _AtomType.humanist => 'humanist',
      _AtomType.idealist => 'idealist',
      _AtomType.agent => 'agent',
    };
    final stateKey = switch (state) {
      _AtomState.base => 'base',
      _AtomState.over => 'over',
      _AtomState.under => 'under',
    };
    return '$_atomAssetBasePath/${typeKey}_$stateKey.jpg';
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

class _LineChartArea extends StatefulWidget {
  const _LineChartArea({
    required this.selfScores,
    required this.otherScores,
    required this.selfLabels,
    required this.otherLabels,
    this.startOffset = 0,
  });

  final List<double?> selfScores;
  final List<double?> otherScores;
  final List<String> selfLabels;
  final List<String> otherLabels;
  final double startOffset;

  @override
  State<_LineChartArea> createState() => _LineChartAreaState();
}

class _LineChartAreaState extends State<_LineChartArea> {
  int? _selected;

  static const _paddingLeft = 32.0;
  static const _paddingRight = 12.0;
  static const _paddingTop = 14.0;
  static const _paddingBottom = 32.0;
  static const _startOffset = 10.0;
  static const _chartHeight = 180.0;

  @override
  Widget build(BuildContext context) {
    final maxVal = _maxValue(widget.selfScores, widget.otherScores);
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final chartWidth = width - _paddingLeft - _paddingRight - (_startOffset * 2);
            final positions = List.generate(widget.selfScores.length, (i) {
              return _paddingLeft + _startOffset + (chartWidth / (widget.selfScores.length - 1)) * i;
            });

            return Stack(
              children: [
                SizedBox(
                  height: _chartHeight,
                  width: width,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (d) {
                      final x = d.localPosition.dx;
                      int nearest = 0;
                      double minDist = double.infinity;
                      for (var i = 0; i < positions.length; i++) {
                        final dist = (positions[i] - x).abs();
                        if (dist < minDist) {
                          minDist = dist;
                          nearest = i;
                        }
                      }
                      setState(() => _selected = nearest);
                    },
                    child: CustomPaint(
                      painter: _LineChartPainter(
                        selfScores: widget.selfScores,
                        otherScores: widget.otherScores,
                        maxValue: maxVal,
                        paddingLeft: _paddingLeft,
                        paddingRight: _paddingRight,
                        paddingTop: _paddingTop,
                        paddingBottom: _paddingBottom,
                        startOffset: widget.startOffset,
                        showPointLabels: true,
                      ),
                    ),
                  ),
                ),
                if (_selected != null)
                  Positioned(
                    left: () {
                      final raw = positions[_selected!] - 60;
                      final minX = 8.0;
                      final maxX = width - 140;
                      return raw.clamp(minX, maxX);
                    }(),
                    top: 12,
                    child: _TooltipBox(
                      selfScore: widget.selfScores[_selected!],
                      otherScore: widget.otherScores[_selected!],
                      selfLabel: widget.selfLabels[_selected!],
                      otherLabel: widget.otherLabels[_selected!],
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        _xLabels(widget.selfLabels, widget.otherLabels),
      ],
    );
  }

  Widget _xLabels(List<String> selfLabels, List<String> otherLabels) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth / selfLabels.length).clamp(40.0, 120.0);
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(selfLabels.length, (i) {
            return SizedBox(
              width: itemWidth,
              child: Column(
                children: [
                  Text(
                    selfLabels[i],
                    style:
                        AppTextStyles.caption.copyWith(color: Colors.red, fontWeight: FontWeight.w700, fontSize: 11),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    otherLabels[i],
                    style:
                        AppTextStyles.caption.copyWith(color: Colors.blue, fontWeight: FontWeight.w700, fontSize: 11),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  double _maxValue(List<double?> a, List<double?> b) {
    final vals = <double>[
      ...a.whereType<double>(),
      ...b.whereType<double>(),
    ];
    final double maxVal = vals.isEmpty ? 100 : vals.reduce(max);
    return max(maxVal, 100.0);
  }
}

class _LabelInfo {
  const _LabelInfo({
    required this.index,
    required this.isSelf,
    required this.anchor,
    required this.textPainter,
    required this.color,
  });

  final int index;
  final bool isSelf;
  final Offset anchor;
  final TextPainter textPainter;
  final Color color;

  Size get size => textPainter.size;
}

class _LabelCandidate {
  const _LabelCandidate({
    required this.info,
    required this.rect,
    required this.collisionRect,
  });

  final _LabelInfo info;
  final Rect rect;
  final Rect collisionRect;
}

class _PairPlacement {
  const _PairPlacement({
    required this.selfCandidate,
    required this.otherCandidate,
  });

  final _LabelCandidate selfCandidate;
  final _LabelCandidate otherCandidate;
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.selfScores,
    required this.otherScores,
    required this.maxValue,
    required this.paddingLeft,
    required this.paddingRight,
    required this.paddingTop,
    required this.paddingBottom,
    this.startOffset = 0,
    required this.showPointLabels,
  });

  final List<double?> selfScores;
  final List<double?> otherScores;
  final double maxValue;
  final double paddingLeft;
  final double paddingRight;
  final double paddingTop;
  final double paddingBottom;
  final double startOffset;
  final bool showPointLabels;

  @override
  void paint(Canvas canvas, Size size) {
    final chartWidth = size.width - paddingLeft - paddingRight - (startOffset * 2);
    final chartHeight = size.height - paddingTop - paddingBottom;
    final paintGrid = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;
    final axisTextPainter = TextPainter(textDirection: TextDirection.ltr);

    const stepValue = 20.0;
    final steps = max(1, (maxValue / stepValue).ceil());
    for (var i = 0; i <= steps; i++) {
      final ratio = i / steps;
      final y = paddingTop + chartHeight * (1 - ratio);
      canvas.drawLine(Offset(paddingLeft, y), Offset(size.width - paddingRight, y), paintGrid);

      final value = stepValue * i;
      axisTextPainter
        ..text = TextSpan(
          text: value.toStringAsFixed(0),
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        )
        ..layout();
      axisTextPainter.paint(
        canvas,
        Offset(paddingLeft - axisTextPainter.width - 6, y - axisTextPainter.height / 2),
      );
    }

    final positions = List.generate(selfScores.length, (i) {
      final x = paddingLeft + startOffset + (chartWidth / (selfScores.length - 1)) * i;
      return x;
    });

    double valueToY(double? value) {
      final v = (value ?? 0).clamp(0, maxValue);
      final ratio = v / maxValue;
      return paddingTop + chartHeight * (1 - ratio);
    }

    final selfPoints = List<Offset>.generate(
      selfScores.length,
      (i) => Offset(positions[i], valueToY(selfScores[i])),
    );
    final otherPoints = List<Offset>.generate(
      otherScores.length,
      (i) => Offset(positions[i], valueToY(otherScores[i])),
    );

    void drawSeries(List<Offset> points, Color color) {
      if (points.isEmpty) return;
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );

      for (final point in points) {
        canvas.drawCircle(point, 5, Paint()..color = color);
      }
    }

    drawSeries(otherPoints, Colors.blue);
    drawSeries(selfPoints, Colors.red);

    if (!showPointLabels) return;

    // ---------------------------------------------------------------------
    // Label placement rules (no leader lines, point-outward, no skip):
    //
    // 1) Labels use LabelSafeRect (whole chart) so first/last never disappear.
    // 2) Each index is a pair; labels are placed together to avoid ambiguity.
    // 3) Labels must stay OUT of the pair corridor (the vertical band between
    //    the two points), or the eye will mis-assign the value.
    // 4) The upper point's label goes above, the lower point's label goes
    //    below (outward from the pair). Color does not decide direction.
    // 5) The label center must be closer to its own point than the other point.
    // 6) Only small moves are allowed: L1/L2 lanes and dx offsets 0, +8, -8, +16, -16.
    // 7) Never skip: if L1/L2 fail, shrink font once, then allow L3.
    // ---------------------------------------------------------------------
    const markerRadius = 5.0;
    const pointLabelGap = 8.0;
    const laneGap = 3.0;
    const labelGap = 4.0;
    const safeInset = 4.0;
    const corridorPad = 8.0;
    const corridorSidePad = 4.0;
    const fontSizePrimary = 11.0;
    const fontSizeFallback = 10.0;

    final labelSafeRect = Rect.fromLTWH(0, 0, size.width, size.height).deflate(safeInset);

    String formatLabel(double? value) {
      return (value ?? 0).toStringAsFixed(1).replaceAll(RegExp(r'\.0\$'), '');
    }

    final selfTexts = selfScores.map(formatLabel).toList();
    final otherTexts = otherScores.map(formatLabel).toList();

    _LabelInfo buildLabelInfo({
      required int index,
      required bool isSelf,
      required double fontSize,
    }) {
      final anchor = isSelf ? selfPoints[index] : otherPoints[index];
      final text = isSelf ? selfTexts[index] : otherTexts[index];
      final style = TextStyle(
        fontSize: fontSize,
        color: isSelf ? Colors.red : Colors.blue,
        fontWeight: FontWeight.w700,
      );
      final painter = TextPainter(textDirection: TextDirection.ltr)
        ..text = TextSpan(text: text, style: style)
        ..layout();
      return _LabelInfo(
        index: index,
        isSelf: isSelf,
        anchor: anchor,
        textPainter: painter,
        color: style.color ?? Colors.black,
      );
    }

    int alignModeForIndex(int index, int lastIndex) {
      // -1 = left-align (text grows right), 0 = center, 1 = right-align (text grows left).
      if (index == 0) return -1;
      if (index == lastIndex) return 1;
      return 0;
    }

    double alignedLeft(double anchorX, double width, int alignMode, double dx) {
      if (alignMode < 0) return anchorX + dx;
      if (alignMode > 0) return anchorX - width + dx;
      return anchorX - width / 2 + dx;
    }

    List<List<int>> laneCombosForMax(int maxLane) {
      final combos = <List<int>>[];
      void add(int a, int b) => combos.add([a, b]);
      add(1, 1);
      if (maxLane >= 2) {
        add(2, 1);
        add(1, 2);
        add(2, 2);
      }
      if (maxLane >= 3) {
        add(3, 1);
        add(1, 3);
        add(3, 2);
        add(2, 3);
        add(3, 3);
      }
      return combos;
    }

    List<List<double>> dxPairsForAlign(int alignMode) {
      if (alignMode < 0) return const [
        [0, 0],
        [8, 8],
        [16, 16],
      ];
      if (alignMode > 0) return const [
        [0, 0],
        [-8, -8],
        [-16, -16],
      ];
      return const [
        [0, 0],
        [8, -8],
        [-8, 8],
        [16, -16],
        [-16, 16],
      ];
    }

    Rect clampToSafeRect(Rect rect) {
      var dx = 0.0;
      var dy = 0.0;

      if (rect.left < labelSafeRect.left) {
        dx = labelSafeRect.left - rect.left;
      }
      if (rect.right + dx > labelSafeRect.right) {
        dx = labelSafeRect.right - rect.right;
      }
      if (rect.top < labelSafeRect.top) {
        dy = labelSafeRect.top - rect.top;
      }
      if (rect.bottom + dy > labelSafeRect.bottom) {
        dy = labelSafeRect.bottom - rect.bottom;
      }

      return rect.shift(Offset(dx, dy));
    }

    bool rectFitsSafeRect(Rect rect) {
      return rect.left >= labelSafeRect.left &&
          rect.top >= labelSafeRect.top &&
          rect.right <= labelSafeRect.right &&
          rect.bottom <= labelSafeRect.bottom;
    }

    Rect pairCorridorRect(_LabelInfo a, _LabelInfo b) {
      final minY = min(a.anchor.dy, b.anchor.dy) - corridorPad;
      final maxY = max(a.anchor.dy, b.anchor.dy) + corridorPad;
      final halfWidth = max(a.size.width, b.size.width) / 2 + corridorSidePad;
      final centerX = a.anchor.dx;
      return Rect.fromLTRB(centerX - halfWidth, minY, centerX + halfWidth, maxY);
    }

    double dist2(Offset a, Offset b) {
      final dx = a.dx - b.dx;
      final dy = a.dy - b.dy;
      return (dx * dx) + (dy * dy);
    }

    bool closerToOwnPoint(_LabelInfo info, Offset otherAnchor, Rect rect) {
      final center = rect.center;
      final selfDist = dist2(center, info.anchor);
      final otherDist = dist2(center, otherAnchor);
      return selfDist < otherDist - 0.5;
    }

    Rect buildLabelRect({
      required _LabelInfo info,
      required bool isTop,
      required int lane,
      required double dx,
      required int alignMode,
    }) {
      final laneOffset = (info.size.height + laneGap) * (lane - 1);
      final top = isTop
          ? info.anchor.dy - pointLabelGap - info.size.height - laneOffset
          : info.anchor.dy + pointLabelGap + laneOffset;
      final left = alignedLeft(info.anchor.dx, info.size.width, alignMode, dx);
      return Rect.fromLTWH(left, top, info.size.width, info.size.height);
    }

    _LabelCandidate? buildCandidate({
      required _LabelInfo info,
      required bool isTop,
      required int lane,
      required double dx,
      required int alignMode,
    }) {
      final rawRect = buildLabelRect(
        info: info,
        isTop: isTop,
        lane: lane,
        dx: dx,
        alignMode: alignMode,
      );
      final rect = clampToSafeRect(rawRect);
      if (!rectFitsSafeRect(rect)) return null;

      // Do not allow a label to overlap its own marker.
      final markerRect = Rect.fromCircle(center: info.anchor, radius: markerRadius + 1);
      if (rect.overlaps(markerRect)) return null;

      return _LabelCandidate(
        info: info,
        rect: rect,
        collisionRect: rect.inflate(labelGap / 2),
      );
    }

    final placedCollisionRects = <Rect>[];
    final placements = <_LabelCandidate>[];

    bool overlapsPlaced(Rect collisionRect) {
      for (final placed in placedCollisionRects) {
        if (collisionRect.overlaps(placed)) return true;
      }
      return false;
    }

    _PairPlacement? tryPlacePair({
      required _LabelInfo selfInfo,
      required _LabelInfo otherInfo,
      required bool selfIsTopPoint,
      required int alignMode,
      required int maxLane,
      required bool allowPlacedOverlap,
    }) {
      final laneCombos = laneCombosForMax(maxLane);
      final dxPairs = dxPairsForAlign(alignMode);
      final corridor = pairCorridorRect(selfInfo, otherInfo);

      for (final dxPair in dxPairs) {
        final selfDx = dxPair[0];
        final otherDx = dxPair[1];

        for (final lanes in laneCombos) {
          final selfCandidate = buildCandidate(
            info: selfInfo,
            isTop: selfIsTopPoint,
            lane: lanes[0],
            dx: selfDx,
            alignMode: alignMode,
          );
          final otherCandidate = buildCandidate(
            info: otherInfo,
            isTop: !selfIsTopPoint,
            lane: lanes[1],
            dx: otherDx,
            alignMode: alignMode,
          );
          if (selfCandidate == null || otherCandidate == null) continue;

          // Reject if any label enters the corridor between the two points.
          if (selfCandidate.rect.overlaps(corridor)) continue;
          if (otherCandidate.rect.overlaps(corridor)) continue;

          // Reject if a label is closer to the other point (confusion risk).
          if (!closerToOwnPoint(selfInfo, otherInfo.anchor, selfCandidate.rect)) continue;
          if (!closerToOwnPoint(otherInfo, selfInfo.anchor, otherCandidate.rect)) continue;

          if (selfCandidate.collisionRect.overlaps(otherCandidate.collisionRect)) continue;
          if (!allowPlacedOverlap && overlapsPlaced(selfCandidate.collisionRect)) continue;
          if (!allowPlacedOverlap && overlapsPlaced(otherCandidate.collisionRect)) continue;

          return _PairPlacement(
            selfCandidate: selfCandidate,
            otherCandidate: otherCandidate,
          );
        }
      }
      return null;
    }

    for (var i = 0; i < selfPoints.length; i++) {
      final alignMode = alignModeForIndex(i, selfPoints.length - 1);
      final selfIsTopPoint = selfPoints[i].dy <= otherPoints[i].dy;

      final selfPrimary = buildLabelInfo(index: i, isSelf: true, fontSize: fontSizePrimary);
      final otherPrimary = buildLabelInfo(index: i, isSelf: false, fontSize: fontSizePrimary);

      // Primary: outward placement using L1/L2 and the base font size.
      var placement = tryPlacePair(
        selfInfo: selfPrimary,
        otherInfo: otherPrimary,
        selfIsTopPoint: selfIsTopPoint,
        alignMode: alignMode,
        maxLane: 2,
        allowPlacedOverlap: false,
      );

      // Fallback 1: shrink font one step and retry L1/L2.
      if (placement == null) {
        final selfSmall = buildLabelInfo(index: i, isSelf: true, fontSize: fontSizeFallback);
        final otherSmall = buildLabelInfo(index: i, isSelf: false, fontSize: fontSizeFallback);
        placement = tryPlacePair(
          selfInfo: selfSmall,
          otherInfo: otherSmall,
          selfIsTopPoint: selfIsTopPoint,
          alignMode: alignMode,
          maxLane: 2,
          allowPlacedOverlap: false,
        );

        // Fallback 2: allow L3 with the smaller font.
        placement ??= tryPlacePair(
          selfInfo: selfSmall,
          otherInfo: otherSmall,
          selfIsTopPoint: selfIsTopPoint,
          alignMode: alignMode,
          maxLane: 3,
          allowPlacedOverlap: false,
        );

        // Fallback 3 (no-skip): last resort allows overlap with other indices.
        placement ??= tryPlacePair(
          selfInfo: selfSmall,
          otherInfo: otherSmall,
          selfIsTopPoint: selfIsTopPoint,
          alignMode: alignMode,
          maxLane: 3,
          allowPlacedOverlap: true,
        );
      }

      if (placement == null) continue;

      final pairCandidates = [placement.selfCandidate, placement.otherCandidate];
      for (final candidate in pairCandidates) {
        placements.add(candidate);
        placedCollisionRects.add(candidate.collisionRect);
      }
    }

    for (final placement in placements) {
      placement.info.textPainter.paint(canvas, placement.rect.topLeft);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _TooltipBox extends StatelessWidget {
  const _TooltipBox({
    required this.selfScore,
    required this.otherScore,
    required this.selfLabel,
    required this.otherLabel,
  });

  final double? selfScore;
  final double? otherScore;
  final String selfLabel;
  final String otherLabel;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(8),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$selfLabel: ${selfScore?.toStringAsFixed(1) ?? '-'}',
                style: AppTextStyles.caption.copyWith(color: Colors.red, fontWeight: FontWeight.w700)),
            Text('$otherLabel: ${otherScore?.toStringAsFixed(1) ?? '-'}',
                style: AppTextStyles.caption.copyWith(color: Colors.blue, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
