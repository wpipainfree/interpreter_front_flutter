import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../services/ai_assistant_service.dart';
import '../../services/auth_service.dart';
import '../../services/psych_tests_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
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
  static const _selfKeys = ['realist', 'romantic', 'humanist', 'idealist', 'agent'];
  static const _standardKeys = ['relation', 'trust', 'manual', 'self', 'culture'];
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
        _error = '로그인 정보를 확인할 수 없습니다.';
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
        _loading = false;
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
        if (checklist.contains('자기') || !_standardKeys.contains(key)) {
          selfScores[key] = value;
        }
        continue;
      }
      if (_standardKeys.contains(key)) {
        if (checklist.contains('타인') || !_selfKeys.contains(key)) {
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
  Future<void> _startInterpretation() async {
    if (_selectedReality == null) {
      _showMessage('현실 검사 결과를 선택해주세요.');
      return;
    }
    setState(() {
      _messages.clear();
      _conversationId = null;
      _turn = 1;
      _status = null;
      _lastLogId = null;
    });
    _stopPolling();
    await _submitInterpretation(phase: 1);
  }
  Future<void> _submitInterpretation({required int phase, String? followup}) async {
    if (_selectedReality == null) return;
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _status = 'in_progress';
    });
    final sessionId = _conversationId;
    if (sessionId != null) {
      _startPolling(sessionId);
    }
    try {
      final realityProfile = await _loadProfile(_selectedReality!);
      if (realityProfile == null) {
        _showMessage('현실 검사 결과를 불러오지 못했습니다.');
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
        if (followup != null && followup.isNotEmpty) 'followup': {'question': followup},
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
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'failed');
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
        final responseMessage = last['response_message']?.toString().trim() ?? '';
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
          _stopPolling();
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
  void _sendFollowup() {
    final text = _inputController.text.trim();
    if (text.isEmpty || _submitting) return;
    if (_conversationId == null) {
      _showMessage('먼저 해석을 시작해주세요.');
      return;
    }
    _inputController.clear();
    _submitInterpretation(phase: 3, followup: text);
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
    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              Text('해석', style: AppTextStyles.h4),
              const SizedBox(height: 12),
              _buildSelector(
                title: '현실 검사',
                items: _realityItems,
                selected: _selectedReality,
                onChanged: (item) => setState(() => _selectedReality = item),
                required: true,
              ),
              const SizedBox(height: 12),
              _buildIdealToggle(),
              if (_useIdeal) ...[
                const SizedBox(height: 12),
                _buildSelector(
                  title: '이상 검사',
                  items: _idealItems,
                  selected: _selectedIdeal,
                  onChanged: (item) => setState(() => _selectedIdeal = item),
                  required: false,
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
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('해석 시작'),
                ),
              ),
              if (_status != null) ...[
                const SizedBox(height: 8),
                Text(
                  '상태: $_status',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
              const SizedBox(height: 16),
              if (_messages.isEmpty)
                _infoCard(
                  '해석 결과가 없습니다.',
                  '현실 검사 결과를 선택한 뒤 해석을 시작해 주세요.',
                )
              else
                ..._messages.map(_buildMessageBubble),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    minLines: 1,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: '추가 질문을 입력하세요',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _submitting ? null : _sendFollowup,
                  icon: const Icon(Icons.send),
                  color: AppColors.primary,
                ),
              ],
            ),
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
        title: Text('이상 프로파일 포함', style: AppTextStyles.bodyMedium),
        subtitle: disabled
            ? Text(
                '이상 검사 결과가 없습니다.',
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              )
            : Text(
                '이상 검사는 선택 사항입니다.',
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
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
              Text(title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
              if (required) ...[
                const SizedBox(width: 6),
                Text('필수', style: AppTextStyles.caption.copyWith(color: AppColors.warning)),
              ],
            ],
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Text(
              '완료된 검사 결과가 없습니다.',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            )
          else
            DropdownButtonFormField<UserAccountItem>(
              value: selected,
              items: items
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(
                        _itemLabel(item),
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
        ],
      ),
    );
  }
  String _itemLabel(UserAccountItem item) {
    final date = _itemDate(item);
    final dateText =
        '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    final target = item.result?['TEST_TARGET_NAME'] ?? '';
    if (target is String && target.isNotEmpty) {
      return '$dateText · $target';
    }
    return dateText;
  }
  Widget _infoCard(String title, String subtitle) {
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
          Text(title, style: AppTextStyles.h5),
          const SizedBox(height: 6),
          Text(subtitle, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
  Widget _buildMessageBubble(_ChatMessage message) {
    final isUser = message.isUser;
    final align = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final color = isUser ? AppColors.primary.withOpacity(0.12) : Colors.white;
    final borderColor = isUser ? AppColors.primary.withOpacity(0.2) : AppColors.border;
    final textColor = isUser ? AppColors.primary : AppColors.textPrimary;
    final baseTextStyle = AppTextStyles.bodySmall.copyWith(color: textColor, height: 1.4);
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
                      h1: baseTextStyle.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
                      h2: baseTextStyle.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                      h3: baseTextStyle.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
                      strong: baseTextStyle.copyWith(fontWeight: FontWeight.w700),
                      em: baseTextStyle.copyWith(fontStyle: FontStyle.italic),
                      blockquotePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
  factory _ChatMessage.user(String text) => _ChatMessage(isUser: true, text: text);
  factory _ChatMessage.assistant(String text) => _ChatMessage(isUser: false, text: text);
  final bool isUser;
  final String text;
}
