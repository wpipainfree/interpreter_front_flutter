import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../services/ai_assistant_service.dart';
import '../../services/auth_service.dart';
import '../../services/psych_tests_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../result/user_result_detail_screen.dart';

enum _InterpretationUiState { idle, creating, polling, ready, failed }

class InterpretationPanel extends StatefulWidget {
  const InterpretationPanel({super.key});

  @override
  State<InterpretationPanel> createState() => _InterpretationPanelState();
}

class _InterpretationPanelState extends State<InterpretationPanel> {
  final PsychTestsService _testsService = PsychTestsService();
  final AiAssistantService _aiService = AiAssistantService();
  final AuthService _authService = AuthService();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final Map<int, _WpiScoreProfile> _profileCache = {};
  final List<UserAccountItem> _realityItems = [];
  final List<UserAccountItem> _idealItems = [];
  final List<_ChatMessage> _messages = [];

  Timer? _pollTimer;
  bool _polling = false;
  bool _loading = true;
  bool _submitting = false;
  bool _useIdeal = false;
  String? _error;
  String? _status;
  String? _conversationId;
  int _turn = 1;
  int? _lastLogId;
  UserAccountItem? _selectedReality;
  UserAccountItem? _selectedIdeal;
  _InterpretationUiState _uiState = _InterpretationUiState.idle;

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
    _load();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final userId = int.tryParse(_authService.currentUser?.id ?? '');
    if (userId == null) {
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
      _realityItems.sort((a, b) => _itemDate(b).compareTo(_itemDate(a)));
      _idealItems.sort((a, b) => _itemDate(b).compareTo(_itemDate(a)));
      setState(() {
        _selectedReality = _realityItems.isNotEmpty ? _realityItems.first : null;
        _selectedIdeal = _idealItems.isNotEmpty ? _idealItems.first : null;
        if (_idealItems.isEmpty) {
          _useIdeal = false;
        }
        _loading = false;
        _uiState = _InterpretationUiState.idle;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<List<UserAccountItem>> _fetchAllAccounts({
    required int userId,
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
    if (_hasConversation) {
      final proceed = await _confirmNewInterpretation();
      if (!proceed) return;
    }
    setState(() {
      _messages.clear();
      _conversationId = null;
      _turn = 1;
      _status = null;
      _lastLogId = null;
      _uiState = _InterpretationUiState.creating;
      _inputController.clear();
    });
    _stopPolling();
    await _submitInterpretation(phase: 1);
  }

  Future<void> _submitInterpretation({
    required int phase,
    String? followup,
  }) async {
    if (_selectedReality == null) return;
    if (_submitting) return;
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
      final realityProfile = await _loadProfile(_selectedReality!);
      if (realityProfile == null) {
        _showMessage('선택한 결과를 불러오지 못했습니다.');
        setState(() => _uiState = _InterpretationUiState.failed);
        return;
      }
      _WpiScoreProfile idealProfile = const _WpiScoreProfile.empty();
      if (_useIdeal && _selectedIdeal != null) {
        final loaded = await _loadProfile(_selectedIdeal!);
        if (loaded != null) {
          idealProfile = loaded;
        }
      }
      final sessionPayload = <String, dynamic>{
        'turn': _turn,
        if (sessionId != null) 'session_id': sessionId,
      };
      final payload = <String, dynamic>{
        'session': sessionPayload,
        'phase': phase,
        'profiles': {
          'reality': realityProfile.toJson(),
          'ideal': idealProfile.toJson(),
        },
        'model': 'gpt-5.2',
        if (followup != null && followup.isNotEmpty)
          'followup': {'question': followup},
      };
      if (followup != null && followup.isNotEmpty) {
        _appendMessage(_ChatMessage.user(followup));
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
      final interpretation = response['interpretation'] as Map<String, dynamic>?;
      final responseText = interpretation?['response']?.toString().trim() ?? '';
      if (responseText.isNotEmpty) {
        _appendMessage(_ChatMessage.assistant(responseText));
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
      if (!mounted) return;
      setState(() => _submitting = false);
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
      _showMessage('해석을 먼저 생성한 뒤 질문할 수 있어요.');
      return;
    }
    _inputController.clear();
    _submitInterpretation(phase: 3, followup: text);
  }

  void _openPreview(UserAccountItem item) {
    if (item.resultId == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserResultDetailScreen(
          resultId: item.resultId!,
          testId: item.testId,
        ),
      ),
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
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: AppTextStyles.bodyMedium),
            const SizedBox(height: 12),
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
    final buttonLabel =
        _hasConversation ? '새 해석 만들기' : '해석 생성하기';
    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              Text('해석에 사용할 검사', style: AppTextStyles.h4),
              const SizedBox(height: 12),
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
              _buildIdealToggle(),
              if (_useIdeal) ...[
                const SizedBox(height: 12),
                _buildSelector(
                  title: '원하는 나(이상)',
                  items: _idealItems,
                  selected: _selectedIdeal,
                  onChanged: (item) => setState(() => _selectedIdeal = item),
                  required: false,
                  onPreview: _selectedIdeal == null
                      ? null
                      : () => _openPreview(_selectedIdeal!),
                ),
              ],
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
              ..._messages.map(_buildMessageBubble),
              if (_showTyping) ...[
                const SizedBox(height: 4),
                _buildStatusBubble('GPT가 해석을 만들고 있어요'),
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

  Widget _buildIdealToggle() {
    final disabled = _idealItems.isEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: _useIdeal && !disabled,
        onChanged: disabled ? null : (value) => setState(() => _useIdeal = value),
        title: Text('원하는 나(이상) 결과 포함', style: AppTextStyles.bodyMedium),
        subtitle: disabled
            ? Text(
                '아직 "원하는 나" 검사가 없습니다.',
                style:
                    AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              )
            : Text(
                '원하는 나 결과를 함께 보내면 비교 해석이 가능합니다.',
                style:
                    AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
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
                  child: MarkdownBody(
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
                        fontSize: 12,
                      ),
                    ),
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
  const _ChatMessage({required this.isUser, required this.text});
  factory _ChatMessage.user(String text) =>
      _ChatMessage(isUser: true, text: text);
  factory _ChatMessage.assistant(String text) =>
      _ChatMessage(isUser: false, text: text);
  final bool isUser;
  final String text;
}
