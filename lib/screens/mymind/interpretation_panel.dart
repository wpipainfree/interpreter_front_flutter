import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/ai_assistant_service.dart';
import '../../services/auth_service.dart';
import '../../services/psych_tests_service.dart';
import '../../router/app_routes.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../utils/auth_ui.dart';
import '../../utils/strings.dart';
import '../../widgets/app_error_view.dart';

enum _InterpretationUiState { idle, creating, polling, ready, failed }

class InterpretationPanel extends StatefulWidget {
  const InterpretationPanel({
    super.key,
    this.initialRealityResultId,
    this.initialIdealResultId,
    this.mindFocus,
    this.initialSessionId,
    this.initialTurn,
    this.initialPrompt,
    this.phase3Only = false,
  });

  final int? initialRealityResultId;
  final int? initialIdealResultId;
  final String? mindFocus;
  final String? initialSessionId;
  final int? initialTurn;
  final String? initialPrompt;
  final bool phase3Only;

  @override
  State<InterpretationPanel> createState() => _InterpretationPanelState();
}

class _InterpretationPanelState extends State<InterpretationPanel> {
  final PsychTestsService _testsService = PsychTestsService();
  final AiAssistantService _aiService = AiAssistantService();
  final AuthService _authService = AuthService();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final VoidCallback _authListener;
  bool _lastLoggedIn = false;
  String? _lastUserId;

  final Map<int, _WpiScoreProfile> _profileCache = {};
  final List<UserAccountItem> _realityItems = [];
  final List<UserAccountItem> _idealItems = [];
  final List<_ChatMessage> _messages = [];

  Timer? _pollTimer;
  bool _polling = false;
  bool _loading = true;
  bool _submitting = false;
  bool _appliedInitialSelection = false;
  String? _error;
  String? _status;
  String? _conversationId;
  String? _conversationTitle;
  String? _mindFocus;
  int _turn = 1;
  int? _lastLogId;
  int? _activeRealityResultId;
  int? _activeIdealResultId;
  List<Map<String, dynamic>>? _activeSources;
  UserAccountItem? _selectedReality;
  UserAccountItem? _selectedIdeal;
  _InterpretationUiState _uiState = _InterpretationUiState.idle;

  static const _mindFocusStorageKey = 'last_mind_focus_text';
  static const _selfKeys = ['realist', 'romantic', 'humanist', 'idealist', 'agent'];
  static const _standardKeys = ['relation', 'trust', 'manual', 'self', 'culture'];
  static const _suggestedQuestions = [
    '지금 마음 한 문장',
    '가장 큰 충돌은?',
    '오늘 할 수 있는 다음 선택 1개',
  ];
  static const _terminalStatuses = {
    'succeeded',
    'failed',
    'timeout',
    'rate_limited',
    'cancelled',
    'validation_error',
    'api_error',
    'content_filter',
  };

  bool get _canChat => _uiState == _InterpretationUiState.ready;
  bool get _showTyping =>
      _uiState == _InterpretationUiState.creating ||
      _uiState == _InterpretationUiState.polling;
  bool get _hasConversation =>
      _conversationId != null && _messages.isNotEmpty;
  bool get _showSuggestions =>
      _canChat && !_messages.any((message) => message.isUser);

  @override
  void initState() {
    super.initState();
    _mindFocus = widget.mindFocus?.trim();

    final initialSessionId = widget.initialSessionId?.trim();
    if (initialSessionId != null && initialSessionId.isNotEmpty) {
      _conversationId = initialSessionId;
      final turn = widget.initialTurn ?? 1;
      _turn = turn < 1 ? 1 : turn;
      _uiState = _InterpretationUiState.ready;
      _setActiveSources(
        realityResultId: widget.initialRealityResultId,
        idealResultId: widget.initialIdealResultId,
      );
    }

    final initialPrompt = widget.initialPrompt?.trim();
    if (initialPrompt != null && initialPrompt.isNotEmpty) {
      _inputController.text = initialPrompt;
    }

    _lastLoggedIn = _authService.isLoggedIn;
    _lastUserId = _authService.currentUser?.id;
    _authListener = _handleAuthChanged;
    _authService.addListener(_authListener);
    _load();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _authService.removeListener(_authListener);
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    await _loadMindFocusIfNeeded();
    final userId = (_authService.currentUser?.id ?? '').trim();
    if (userId.isEmpty) {
      setState(() {
        _loading = false;
        _error = '사용자 정보를 불러올 수 없습니다.';
      });
      return;
    }
    try {
      final reality = await _fetchAllAccounts(userId: userId, testId: 1);
      final ideal = await _fetchAllAccounts(userId: userId, testId: 3);
      _realityItems
        ..clear()
        ..addAll(reality);
      _idealItems
        ..clear()
        ..addAll(ideal);
      _ensureInitialItemPresent(userId: int.tryParse(userId) ?? 0);
      _realityItems.sort((a, b) => _itemDate(b).compareTo(_itemDate(a)));
      _idealItems.sort((a, b) => _itemDate(b).compareTo(_itemDate(a)));

      final selectedReality = _resolveSelected(
        items: _realityItems,
        initialResultId: _appliedInitialSelection ? null : widget.initialRealityResultId,
        current: _selectedReality,
      );
      final selectedIdeal = _resolveSelected(
        items: _idealItems,
        initialResultId: _appliedInitialSelection ? null : widget.initialIdealResultId,
        current: _selectedIdeal,
      );

      if ((_conversationId ?? '').trim().isNotEmpty &&
          (_activeSources == null || _activeSources!.isEmpty)) {
        _setActiveSources(
          realityResultId: selectedReality?.resultId,
          idealResultId: selectedIdeal?.resultId,
        );
      }

      setState(() {
        _selectedReality = selectedReality;
        _selectedIdeal = selectedIdeal;
        _appliedInitialSelection = true;
        _loading = false;
        _uiState = (_conversationId ?? '').trim().isNotEmpty
            ? _InterpretationUiState.ready
            : _InterpretationUiState.idle;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _handleAuthChanged() {
    if (!mounted) return;

    final nowLoggedIn = _authService.isLoggedIn;
    final nowUserId = _authService.currentUser?.id;
    if (nowLoggedIn == _lastLoggedIn && nowUserId == _lastUserId) return;

    _lastLoggedIn = nowLoggedIn;
    _lastUserId = nowUserId;

    if (nowLoggedIn) {
      _stopPolling();
      _load();
      return;
    }

    _stopPolling();
    _clearActiveSources();
    setState(() {
      _realityItems.clear();
      _idealItems.clear();
      _messages.clear();
      _selectedReality = null;
      _selectedIdeal = null;
      _conversationId = null;
      _conversationTitle = null;
      _turn = 1;
      _lastLogId = null;
      _status = null;
      _submitting = false;
      _loading = false;
      _error = '로그인이 필요합니다.';
      _uiState = _InterpretationUiState.idle;
    });
  }

  Future<void> _promptLoginAndReload() async {
    final ok = await AuthUi.promptLogin(context: context);
    if (ok && mounted) {
      await _load();
    }
  }

  Future<List<UserAccountItem>> _fetchAllAccounts({
    required String userId,
    required int testId,
  }) async {
    final items = <UserAccountItem>[];
    var page = 1;
    var hasNext = true;
    var safety = 0;
    while (hasNext && safety < 50) {
      safety += 1;
      final res = await _testsService.fetchUserAccounts(
        userId: userId,
        page: page,
        pageSize: 30,
        fetchAll: false,
        testIds: [testId],
      );
      items.addAll(res.items.where((e) => e.resultId != null));
      hasNext = res.hasNext;
      page += 1;
    }
    return items;
  }

  DateTime _itemDate(UserAccountItem item) {
    final raw = item.createDate ?? item.paymentDate ?? item.modifyDate;
    final parsed = raw != null ? DateTime.tryParse(raw) : null;
    return parsed ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<void> _loadMindFocusIfNeeded() async {
    if ((_mindFocus ?? '').trim().isNotEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_mindFocusStorageKey)?.trim();
    if (saved != null && saved.isNotEmpty) {
      _mindFocus = saved;
    }
  }

  void _ensureInitialItemPresent({required int userId}) {
    final initialReality = widget.initialRealityResultId;
    if (initialReality != null && !_realityItems.any((e) => e.resultId == initialReality)) {
      _realityItems.insert(
        0,
        UserAccountItem(
          id: 0,
          userId: userId,
          testId: 1,
          resultId: initialReality,
          createDate: DateTime.now().toIso8601String(),
        ),
      );
    }

    final initialIdeal = widget.initialIdealResultId;
    if (initialIdeal != null && !_idealItems.any((e) => e.resultId == initialIdeal)) {
      _idealItems.insert(
        0,
        UserAccountItem(
          id: 0,
          userId: userId,
          testId: 3,
          resultId: initialIdeal,
          createDate: DateTime.now().toIso8601String(),
        ),
      );
    }
  }

  UserAccountItem? _resolveSelected({
    required List<UserAccountItem> items,
    required int? initialResultId,
    required UserAccountItem? current,
  }) {
    if (items.isEmpty) return null;

    UserAccountItem? findByResultId(int? resultId) {
      if (resultId == null) return null;
      for (final item in items) {
        if (item.resultId == resultId) return item;
      }
      return null;
    }

    final initial = findByResultId(initialResultId);
    if (initial != null) return initial;

    final stillExists = findByResultId(current?.resultId);
    if (stillExists != null) return stillExists;

    return items.first;
  }

  Future<_WpiScoreProfile?> _loadProfile(UserAccountItem item) async {
    final resultId = item.resultId;
    if (resultId == null) return null;
    final cached = _profileCache[resultId];
    if (cached != null) return cached;
    final detail = await _testsService.fetchResultDetail(resultId);
    final profile = _buildProfile(detail);
    _profileCache[resultId] = profile;
    return profile;
  }

  _WpiScoreProfile _buildProfile(UserResultDetail detail) {
    final selfScores = <String, double>{};
    final standardScores = <String, double>{};
    for (final item in detail.classes) {
      final name = item.name ?? '';
      if (name.isEmpty) continue;
      final key = _normalizeKey(name);
      final value = item.point ?? 0;
      final checklist = item.checklistName ?? '';
      if (_selfKeys.contains(key)) {
        if (checklist.contains('자기평가') || !_standardKeys.contains(key)) {
          selfScores[key] = value;
        }
        continue;
      }
      if (_standardKeys.contains(key)) {
        if (checklist.contains('타인평가') || !_selfKeys.contains(key)) {
          standardScores[key] = value;
        }
      }
    }
    return _WpiScoreProfile(
      selfScores: _fillScores(_selfKeys, selfScores),
      standardScores: _fillScores(_standardKeys, standardScores),
    );
  }

  Map<String, double> _fillScores(List<String> keys, Map<String, double> raw) {
    return {for (final key in keys) key: raw[key] ?? 0};
  }

  String _normalizeKey(String raw) {
    final normalized = raw.toLowerCase().replaceAll(' ', '').split('/').first;
    if (normalized == 'romantist' || normalized == 'romanticist') return 'romantic';
    return normalized;
  }

  void _setActiveSources({
    required int? realityResultId,
    required int? idealResultId,
  }) {
    _activeRealityResultId = realityResultId;
    _activeIdealResultId = idealResultId;
    _activeSources = _buildSources(
      realityResultId: realityResultId,
      idealResultId: idealResultId,
    );
  }

  void _clearActiveSources() {
    _activeRealityResultId = null;
    _activeIdealResultId = null;
    _activeSources = null;
  }

  List<Map<String, dynamic>> _buildSources({
    required int? realityResultId,
    required int? idealResultId,
  }) {
    final sources = <Map<String, dynamic>>[];
    if (realityResultId != null && realityResultId > 0) {
      sources.add({'result_id': realityResultId, 'role': 'reality'});
    }
    if (idealResultId != null && idealResultId > 0) {
      sources.add({'result_id': idealResultId, 'role': 'ideal'});
    }
    return sources;
  }

  UserAccountItem? _resolveActiveItem({
    required int? resultId,
    required int testId,
    required List<UserAccountItem> items,
  }) {
    if (resultId == null) return null;
    for (final item in items) {
      if (item.resultId == resultId) return item;
    }
    final userId = int.tryParse(_authService.currentUser?.id ?? '') ?? 0;
    return UserAccountItem(
      id: 0,
      userId: userId,
      testId: testId,
      resultId: resultId,
      createDate: DateTime.now().toIso8601String(),
    );
  }

  Future<bool> _confirmNewInterpretation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('새 해석을 만들까요?'),
        content: const Text('기존 대화는 기록 탭에서 확인할 수 있어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('새 해석 만들기'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _startInterpretation() async {
    if (_selectedReality == null) {
      _showMessage('먼저 "지금의 나(현실)" 결과를 선택해 주세요.');
      return;
    }
    if (!widget.phase3Only) {
      if (_idealItems.isEmpty) {
        _showMessage('먼저 "원하는 나(이상)" 검사를 완료해 주세요.');
        return;
      }
      if (_selectedIdeal == null) {
        _showMessage('먼저 "원하는 나(이상)" 결과를 선택해 주세요.');
        return;
      }
    }
    if (_hasConversation) {
      final proceed = await _confirmNewInterpretation();
      if (!proceed) return;
    }
    _setActiveSources(
      realityResultId: _selectedReality?.resultId,
      idealResultId: _selectedIdeal?.resultId,
    );
    setState(() {
      _messages.clear();
      _conversationId = null;
      _conversationTitle = null;
      _turn = 1;
      _status = null;
      _lastLogId = null;
      _uiState = _InterpretationUiState.creating;
      _inputController.clear();
    });
    _stopPolling();
    await _submitInterpretation(phase: 1);
    if (!mounted) return;
    final focus = (_mindFocus ?? '').trim();
    if (focus.isNotEmpty && (_conversationId ?? '').isNotEmpty) {
      await _submitInterpretation(phase: 2);
    }
  }

  Future<void> _submitInterpretation({
    required int phase,
    String? followup,
  }) async {
    if (_selectedReality == null) return;
    if (_submitting) return;

    final isPhase1 = phase == 1;
    final isPhase2 = phase == 2;
    final isPhase3 = phase == 3;
    if (!isPhase1 && !isPhase2 && !isPhase3) {
      _showMessage('Invalid phase: $phase');
      return;
    }

    if (!widget.phase3Only && _selectedIdeal == null) {
      _showMessage('먼저 "원하는 나(이상)" 결과를 선택해 주세요.');
      return;
    }

    final trimmedMindFocus = (_mindFocus ?? '').trim();
    final trimmedFollowup = (followup ?? '').trim();

    if (isPhase2 && trimmedMindFocus.isEmpty) {
      _showMessage('마음 포커스가 비어있어 Phase 2를 진행할 수 없습니다.');
      return;
    }
    if (isPhase3) {
      if ((_conversationId ?? '').isEmpty) {
        _showMessage('세션이 없습니다. 먼저 해석을 시작해주세요.');
        return;
      }
      if (trimmedFollowup.isEmpty) {
        _showMessage('추가 질문을 입력해주세요.');
        return;
      }
    }

    setState(() {
      _submitting = true;
      _status = 'in_progress';
      _uiState = _conversationId == null
          ? _InterpretationUiState.creating
          : _InterpretationUiState.polling;
    });
    final sessionId = _conversationId;
    if (sessionId != null) {
      _startPolling(sessionId);
    }
    try {
      final activeRealityId = _activeRealityResultId ?? _selectedReality?.resultId;
      final activeIdealId = _activeIdealResultId ?? _selectedIdeal?.resultId;
      if (_activeSources == null || _activeSources!.isEmpty) {
        _setActiveSources(
          realityResultId: activeRealityId,
          idealResultId: activeIdealId,
        );
      }
      final sources = _activeSources ??
          _buildSources(
            realityResultId: activeRealityId,
            idealResultId: activeIdealId,
          );
      final realityItem = _resolveActiveItem(
        resultId: activeRealityId,
        testId: 1,
        items: _realityItems,
      );
      if (realityItem == null) {
        _showMessage('선택한 결과를 불러오지 못했습니다.');
        setState(() => _uiState = _InterpretationUiState.failed);
        return;
      }
      final realityProfile = await _loadProfile(realityItem);
      if (realityProfile == null) {
        _showMessage('선택한 결과를 불러오지 못했습니다.');
        setState(() => _uiState = _InterpretationUiState.failed);
        return;
      }
      _WpiScoreProfile idealProfile = const _WpiScoreProfile.empty();
      if (activeIdealId != null) {
        final idealItem = _resolveActiveItem(
          resultId: activeIdealId,
          testId: 3,
          items: _idealItems,
        );
        if (idealItem != null) {
          final loaded = await _loadProfile(idealItem);
          if (loaded != null) {
            idealProfile = loaded;
          }
        }
      }
      final sessionPayload = <String, dynamic>{
        if (sessionId != null) 'session_id': sessionId,
        'turn': _turn,
      };
      final payload = <String, dynamic>{
        'session': sessionPayload,
        'phase': phase,
        'sources': sources,
        'profiles': {
          'reality': realityProfile.toJson(),
          'ideal': idealProfile.toJson(),
        },
        'model': 'gpt-5.2',
        if (isPhase2) 'story': {'content': trimmedMindFocus},
        if (isPhase3) 'followup': {'question': trimmedFollowup},
      };
      if (isPhase3) {
        _appendMessage(_ChatMessage.user(trimmedFollowup));
      }
      final response = await _aiService.interpret(payload);
      final session = response['session'] as Map<String, dynamic>?;
      final responseSessionId = session?['session_id']?.toString();
      final responseTurn = session?['turn'] as int?;
      if (responseSessionId != null && responseSessionId.isNotEmpty) {
        _conversationId = responseSessionId;
      }
      if (_conversationId != null && _pollTimer == null) {
        _startPolling(_conversationId!);
      }
      final interpretationRaw = response['interpretation'];
      final interpretation =
          interpretationRaw is Map ? interpretationRaw.cast<String, dynamic>() : null;
      final responseTitle = interpretation?['title']?.toString().trim() ?? '';
      final responseText = (interpretation?['response'] ?? interpretationRaw)
              ?.toString()
              .trim() ??
          '';

      if ((_conversationTitle ?? '').trim().isEmpty && responseTitle.isNotEmpty) {
        setState(() => _conversationTitle = responseTitle);
      }

      if (responseText.isNotEmpty || responseTitle.isNotEmpty) {
        _appendMessage(
          _ChatMessage.assistant(
            responseText,
            title: responseTitle.isNotEmpty ? responseTitle : null,
          ),
        );
      }
      setState(() {
        _status = 'succeeded';
        _turn = (responseTurn ?? _turn) + 1;
        _uiState = _InterpretationUiState.ready;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _uiState = _InterpretationUiState.failed);
      _showMessage(e.toString());
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      } else {
        _submitting = false;
      }
      if (_status != null && _terminalStatuses.contains(_status)) {
        _stopPolling();
      }
    }
  }

  void _startPolling(String conversationId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _pollConversation(conversationId),
    );
    if (_uiState != _InterpretationUiState.ready) {
      setState(() => _uiState = _InterpretationUiState.polling);
    }
    _pollConversation(conversationId);
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _pollConversation(String conversationId) async {
    if (_polling) return;
    _polling = true;
    try {
      final data = await _aiService.fetchConversation(conversationId);
      final entries = data['entries'] as List<dynamic>? ?? const [];
      if (entries.isNotEmpty) {
        final last = entries.last as Map<String, dynamic>;
        final status = last['status']?.toString();
        final logId = last['log_id'] as int?;
        final responseMessage =
            last['response_message']?.toString().trim() ?? '';
        if (status != null && status != _status) {
          setState(() => _status = status);
        }
        if (status == 'succeeded' && logId != null && logId != _lastLogId) {
          _lastLogId = logId;
          if (responseMessage.isNotEmpty) {
            _appendMessage(_ChatMessage.assistant(responseMessage));
          }
        }
        if (status != null && _terminalStatuses.contains(status)) {
          if (status == 'succeeded') {
            setState(() => _uiState = _InterpretationUiState.ready);
          } else {
            setState(() => _uiState = _InterpretationUiState.failed);
          }
          _stopPolling();
        } else if (_uiState != _InterpretationUiState.ready) {
          setState(() => _uiState = _InterpretationUiState.polling);
        }
      }
    } catch (_) {
      // Ignore polling errors to keep UI responsive.
    } finally {
      _polling = false;
    }
  }

  void _appendMessage(_ChatMessage message) {
    if (_messages.isNotEmpty) {
      final last = _messages.last;
      if (last.isUser == message.isUser && last.text == message.text) {
        final lastTitle = (last.title ?? '').trim();
        final nextTitle = (message.title ?? '').trim();
        if (lastTitle.isEmpty && nextTitle.isNotEmpty) {
          setState(() => _messages[_messages.length - 1] = last.copyWith(title: nextTitle));
        }
        return;
      }
    }
    setState(() => _messages.add(message));
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _sendSuggested(String text) {
    if (!_canChat || _submitting) return;
    _inputController.clear();
    _submitInterpretation(phase: 3, followup: text);
  }

  void _sendFollowup() {
    final text = _inputController.text.trim();
    if (text.isEmpty || _submitting) return;
    if (!_canChat || _conversationId == null) {
      _showMessage(AppStrings.interpretationNeedsFirstAnswer);
      return;
    }
    _inputController.clear();
    _submitInterpretation(phase: 3, followup: text);
  }

  void _openPreview(UserAccountItem item) {
    if (item.resultId == null) return;
    Navigator.of(context).pushNamed(
      AppRoutes.userResultDetail,
      arguments: UserResultDetailArgs(resultId: item.resultId!, testId: item.testId),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
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
    final buttonLabel =
        _hasConversation ? '새 해석 만들기' : '해석 생성하기';
    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              if (!widget.phase3Only) ...[
                Text(
                  (_conversationTitle ?? '').trim().isNotEmpty
                      ? _conversationTitle!.trim()
                      : '해석에 사용할 검사',
                  style: AppTextStyles.h4,
                ),
                const SizedBox(height: 12),
                if ((_mindFocus ?? '').trim().isNotEmpty) ...[
                  _buildMindFocusCard(_mindFocus!.trim()),
                  const SizedBox(height: 12),
                ],
                _buildSelector(
                  title: '지금의 나(현실)',
                  items: _realityItems,
                  selected: _selectedReality,
                  onChanged: (item) => setState(() => _selectedReality = item),
                  required: true,
                  onPreview: _selectedReality == null
                      ? null
                      : () => _openPreview(_selectedReality!),
                ),
                const SizedBox(height: 12),
                _buildSelector(
                  title: '원하는 나(이상)',
                  items: _idealItems,
                  selected: _selectedIdeal,
                  onChanged: (item) => setState(() => _selectedIdeal = item),
                  required: true,
                  onPreview: _selectedIdeal == null
                      ? null
                      : () => _openPreview(_selectedIdeal!),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _startInterpretation,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(buttonLabel),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '선택한 검사 결과를 바탕으로 기준–믿음 구조를 먼저 한 문장으로 정리합니다.',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                if (_messages.isEmpty) _buildGuideCard(),
              ] else ...[
                Text('추가 질문', style: AppTextStyles.h4),
                const SizedBox(height: 8),
                Text(
                  '해석을 바탕으로 궁금한 점을 자유롭게 물어보세요.',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary),
                ),
                if (_messages.isEmpty) ...[
                  const SizedBox(height: 12),
                  _buildPhase3GuideCard(),
                ],
              ],
              ..._messages.map(_buildMessageBubble),
              if (_showTyping) ...[
                const SizedBox(height: 4),
                _buildStatusBubble('당신의 마음 구조를 분석하고 있어요'),
              ],
              if (_uiState == _InterpretationUiState.failed) ...[
                const SizedBox(height: 12),
                _buildErrorCard(),
              ],
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_showSuggestions) _buildSuggestionChips(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputController,
                        minLines: 1,
                        maxLines: 3,
                        enabled: _canChat && !_submitting,
                        onSubmitted: (_) => _sendFollowup(),
                        decoration: InputDecoration(
                          hintText: _canChat
                              ? '궁금한 내용을 입력해 주세요'
                              : '해석을 생성한 뒤 질문할 수 있어요',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed:
                          _canChat && !_submitting ? _sendFollowup : null,
                      icon: const Icon(Icons.send),
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMindFocusCard(String mindFocus) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mind focus',
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(mindFocus, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildSelector({
    required String title,
    required List<UserAccountItem> items,
    required UserAccountItem? selected,
    required ValueChanged<UserAccountItem?> onChanged,
    required bool required,
    VoidCallback? onPreview,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (required) ...[
                      const SizedBox(width: 6),
                      Text(
                        '필수',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.warning),
                      ),
                    ],
                  ],
                ),
              ),
              if (onPreview != null)
                TextButton(
                  onPressed: onPreview,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('결과 미리보기'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Text(
              '선택할 수 있는 결과가 없습니다.',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            )
          else
            DropdownButtonFormField<UserAccountItem>(
              value: selected,
              items: items
                  .asMap()
                  .entries
                  .map(
                    (entry) => DropdownMenuItem(
                      value: entry.value,
                      child: Text(
                        _itemLabel(entry.value, isRecent: entry.key == 0),
                        style: AppTextStyles.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
              isExpanded: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
        ],
      ),
    );
  }

  String _itemLabel(UserAccountItem item, {bool isRecent = false}) {
    final date = _itemDate(item);
    final dateText =
        '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    if (isRecent) {
      return '$dateText (최근 검사)';
    }
    return dateText;
  }

  Widget _buildGuideCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('해석을 시작하면 이렇게 나옵니다', style: AppTextStyles.h5),
          const SizedBox(height: 8),
          Text(
            '지금의 나는 “연결되고 싶음”과 “실수하면 안 됨”이 충돌해 긴장도가 올라간 구조입니다.',
            style: AppTextStyles.bodySmall.copyWith(height: 1.4),
          ),
          const SizedBox(height: 8),
          Text(
            '먼저 해석을 생성한 뒤, 추가 질문을 할 수 있어요.',
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildPhase3GuideCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('추천 질문으로 시작해보세요', style: AppTextStyles.h5),
          const SizedBox(height: 8),
          Text(
            '아래 칩을 누르거나, 궁금한 내용을 직접 입력하면 됩니다.',
            style:
                AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBubble(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(text, style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('해석 생성에 실패했습니다.', style: AppTextStyles.h5),
          const SizedBox(height: 6),
          Text(
            '잠시 후 다시 시도해 주세요.',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: _submitting ? null : _startInterpretation,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(40),
            ),
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _suggestedQuestions
            .map(
              (text) => ActionChip(
                label: Text(text),
                onPressed: () => _sendSuggested(text),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage message) {
    final isUser = message.isUser;
    final align = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final color = isUser ? AppColors.primary.withOpacity(0.12) : Colors.white;
    final borderColor =
        isUser ? AppColors.primary.withOpacity(0.2) : AppColors.border;
    final textColor = isUser ? AppColors.primary : AppColors.textPrimary;
    final baseTextStyle =
        AppTextStyles.bodySmall.copyWith(color: textColor, height: 1.4);
    final title = (message.title ?? '').trim();
    final body = message.text.trim();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: align,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: isUser
              ? SelectableText(message.text, style: baseTextStyle)
              : SelectionArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title.isNotEmpty) ...[
                        Text(
                          title,
                          style: baseTextStyle.copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (body.isNotEmpty) const SizedBox(height: 8),
                      ],
                      if (body.isNotEmpty)
                        MarkdownBody(
                          data: message.text,
                          styleSheet: MarkdownStyleSheet(
                            p: baseTextStyle,
                            h1: baseTextStyle.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                            h2: baseTextStyle.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                            h3: baseTextStyle.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
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
                            code: baseTextStyle.copyWith(
                              fontFamily: 'monospace',
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _WpiScoreProfile {
  const _WpiScoreProfile({
    required this.selfScores,
    required this.standardScores,
  });

  const _WpiScoreProfile.empty()
      : selfScores = const {},
        standardScores = const {};

  final Map<String, double> selfScores;
  final Map<String, double> standardScores;

  Map<String, dynamic> toJson() => {
        'self_scores': selfScores,
        'standard_scores': standardScores,
      };
}

class _ChatMessage {
  const _ChatMessage({required this.isUser, required this.text, this.title});

  _ChatMessage copyWith({String? text, String? title}) => _ChatMessage(
        isUser: isUser,
        text: text ?? this.text,
        title: title ?? this.title,
      );

  factory _ChatMessage.user(String text) =>
      _ChatMessage(isUser: true, text: text);
  factory _ChatMessage.assistant(String text, {String? title}) =>
      _ChatMessage(isUser: false, text: text, title: title);
  final bool isUser;
  final String text;
  final String? title;
}
