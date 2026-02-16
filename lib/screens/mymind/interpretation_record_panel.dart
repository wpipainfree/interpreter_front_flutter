import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../app/di/app_scope.dart';
import '../../domain/model/result_models.dart';
import '../../models/initial_interpretation_v1.dart';
import '../../router/app_routes.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../utils/auth_ui.dart';
import '../../utils/main_shell_tab_controller.dart';
import '../../utils/strings.dart';
import '../../widgets/app_error_view.dart';
import '../result/user_result_detail/sections/ideal_profile_section.dart';
import '../result/user_result_detail/sections/reality_profile_section.dart';
import '../result/user_result_detail/widgets/result_section_header.dart';

const _selfKeyLabels = [
  'Realist',
  'Romanticist',
  'Humanist',
  'Idealist',
  'Agent',
];
const _otherKeyLabels = ['Relation', 'Trust', 'Manual', 'Self', 'Culture'];
const _selfDisplayLabels = ['리얼리스트', '로맨티스트', '휴머니스트', '아이디얼리스트', '에이전트'];
const _otherDisplayLabels = ['릴레이션', '트러스트', '매뉴얼', '셀프', '컬처'];

class InterpretationRecordPanel extends StatefulWidget {
  const InterpretationRecordPanel({super.key});

  @override
  State<InterpretationRecordPanel> createState() =>
      _InterpretationRecordPanelState();
}

class _InterpretationRecordPanelState extends State<InterpretationRecordPanel> {
  final _repository = AppScope.instance.resultRepository;
  final ScrollController _scrollController = ScrollController();
  late final VoidCallback _authListener;
  late final VoidCallback _refreshListener;
  bool _lastLoggedIn = false;
  String? _lastUserId;

  final List<_ConversationSummary> _items = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasNext = true;
  int _skip = 0;
  String? _error;

  static const _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _lastLoggedIn = _repository.isLoggedIn;
    _lastUserId = _repository.currentUserId;
    _authListener = _handleAuthChanged;
    _repository.addAuthListener(_authListener);
    _scrollController.addListener(_onScroll);
    _refreshListener = _handleRefresh;
    MainShellTabController.refreshTick.addListener(_refreshListener);
    _loadPage(reset: true);
  }

  @override
  void dispose() {
    _repository.removeAuthListener(_authListener);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    MainShellTabController.refreshTick.removeListener(_refreshListener);
    super.dispose();
  }

  void _handleRefresh() {
    if (!mounted) return;
    if (MainShellTabController.index.value != 2) return;
    _loadPage(reset: true);
  }

  void _handleAuthChanged() {
    if (!mounted) return;

    final nowLoggedIn = _repository.isLoggedIn;
    final nowUserId = _repository.currentUserId;
    if (nowLoggedIn == _lastLoggedIn && nowUserId == _lastUserId) return;

    _lastLoggedIn = nowLoggedIn;
    _lastUserId = nowUserId;

    if (nowLoggedIn) {
      _loadPage(reset: true);
      return;
    }

    setState(() {
      _items.clear();
      _loading = false;
      _loadingMore = false;
      _hasNext = true;
      _skip = 0;
      _error = AppStrings.loginRequired;
    });
  }

  Future<void> _promptLoginAndReload() async {
    final ok = await AuthUi.promptLogin(context: context);
    if (ok && mounted) {
      await _loadPage(reset: true);
    }
  }

  void _onScroll() {
    if (_loading || _loadingMore || !_hasNext) return;
    if (_scrollController.position.extentAfter < 200) {
      _loadPage(reset: false);
    }
  }

  Future<void> _loadPage({required bool reset}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _loadingMore = false;
        _hasNext = true;
        _skip = 0;
        _items.clear();
        _error = null;
      });
    } else {
      if (_loadingMore || !_hasNext) return;
      setState(() => _loadingMore = true);
    }

    try {
      final res = await _repository.fetchConversationSummaries(
        skip: _skip,
        limit: _pageSize,
      );
      final raw = (res['conversations'] ?? res['items'] ?? res['data'])
              as List<dynamic>? ??
          const [];
      final fetched = raw
          .whereType<Map<String, dynamic>>()
          .map(_ConversationSummary.fromJson)
          .toList();
      if (!mounted) return;
      setState(() {
        _items.addAll(fetched);
        _skip += fetched.length;
        _hasNext = fetched.length == _pageSize;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      } else {
        _loading = false;
        _loadingMore = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      final loggedIn = _repository.isLoggedIn;
      return AppErrorView(
        title: loggedIn ? '불러오지 못했어요' : '로그인이 필요합니다',
        message: _error!,
        primaryActionLabel: loggedIn ? AppStrings.retry : AppStrings.login,
        primaryActionStyle: loggedIn
            ? AppErrorPrimaryActionStyle.outlined
            : AppErrorPrimaryActionStyle.filled,
        onPrimaryAction: loggedIn
            ? () => _loadPage(reset: true)
            : () => _promptLoginAndReload(),
      );
    }

    if (_items.isEmpty) {
      return _infoCard(
        AppStrings.recordEmptyTitle,
        AppStrings.recordEmptySubtitle,
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadPage(reset: true),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(20),
        itemBuilder: (context, index) {
          if (index == _items.length) {
            if (_loadingMore) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }
            if (_hasNext) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: OutlinedButton(
                  onPressed: () => _loadPage(reset: false),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44)),
                  child: const Text(AppStrings.seeMore),
                ),
              );
            }
            return const SizedBox.shrink();
          }
          final item = _items[index];
          return _ConversationCard(item: item);
        },
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: _items.length + 1,
      ),
    );
  }

  Widget _infoCard(String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.all(20),
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
          Text(subtitle,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ConversationCard extends StatelessWidget {
  const _ConversationCard({required this.item});

  final _ConversationSummary item;

  @override
  Widget build(BuildContext context) {
    final displayTitle = item.displayTitle;
    final rawTitle = item.title.trim();
    return InkWell(
      onTap: () {
        Navigator.of(context).pushNamed(
          AppRoutes.interpretationRecordDetail,
          arguments: InterpretationRecordDetailArgs(
            conversationId: item.id,
            title: rawTitle,
          ),
        );
      },
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayTitle,
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.w700),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              item.dateRangeLabel,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            Text(
              '메시지 ${item.totalMessages}개',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class InterpretationRecordDetailScreen extends StatefulWidget {
  const InterpretationRecordDetailScreen({
    super.key,
    required this.conversationId,
    required this.title,
  });

  final String conversationId;
  final String title;

  @override
  State<InterpretationRecordDetailScreen> createState() =>
      _InterpretationRecordDetailScreenState();
}

class _InterpretationRecordDetailScreenState
    extends State<InterpretationRecordDetailScreen> {
  final _repository = AppScope.instance.resultRepository;
  final TextEditingController _followupController = TextEditingController();
  final FocusNode _followupFocus = FocusNode();
  bool _loading = true;
  bool _submittingFollowup = false;
  String? _pendingQuestion;
  String? _streamingAnswer;
  String? _streamingFullAnswer;
  int _streamingIndex = 0;
  Timer? _streamingTimer;
  int? _expectedQuestionCount;
  bool _pendingEntryReady = false;
  String? _error;
  String? _resolvedTitle;
  final List<_ConversationEntry> _entries = [];
  UserResultDetail? _reality;
  UserResultDetail? _ideal;
  static const int _maxQuestions = 4;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _followupController.dispose();
    _followupFocus.dispose();
    _streamingTimer?.cancel();
    super.dispose();
  }

  int get _questionCount {
    final baseCount =
        _entries.where((entry) => entry.request.trim().isNotEmpty).length;
    if (_pendingQuestion != null && _pendingEntryReady && _entries.isNotEmpty) {
      return (baseCount - 1).clamp(0, baseCount).toInt();
    }
    return baseCount;
  }

  int get _remainingQuestions =>
      _maxQuestions - (_questionCount + (_pendingQuestion != null ? 1 : 0));

  bool get _canAskMore => _remainingQuestions > 0;

  Future<void> _load({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else if (_error != null) {
      setState(() {
        _error = null;
      });
    }
    try {
      final res = await _repository.fetchConversation(widget.conversationId);
      final resultsRaw = (res['results'] as List<dynamic>?) ?? const [];
      final results = resultsRaw
          .whereType<Map<String, dynamic>>()
          .map(UserResultDetail.fromJson)
          .toList();
      UserResultDetail? reality;
      UserResultDetail? ideal;
      for (final item in results) {
        final testId = item.result.testId;
        if (testId == 1 && reality == null) {
          reality = item;
        } else if (testId == 3 && ideal == null) {
          ideal = item;
        }
      }
      final raw = (res['entries'] ?? res['items'] ?? res['logs'] ?? res['data'])
              as List<dynamic>? ??
          const [];
      final items = raw
          .whereType<Map<String, dynamic>>()
          .map(_ConversationEntry.fromJson)
          .toList();
      if (!mounted) return;
      final nextQuestionCount =
          items.where((entry) => entry.request.trim().isNotEmpty).length;
      final resolvedPending = _expectedQuestionCount != null &&
          nextQuestionCount >= _expectedQuestionCount!;
      final streamingActive = _streamingFullAnswer != null &&
          _streamingIndex < (_streamingFullAnswer?.length ?? 0);
      setState(() {
        if (widget.title.trim().isEmpty) {
          final derived = items
              .map((entry) => entry.title.trim())
              .firstWhere((title) => title.isNotEmpty, orElse: () => '');
          if (derived.isNotEmpty) {
            _resolvedTitle = derived;
          } else {
            final fallback = items
                .map((entry) => entry.request.trim())
                .firstWhere((text) => text.isNotEmpty, orElse: () => '');
            _resolvedTitle =
                fallback.isNotEmpty ? _truncateTitle(fallback) : null;
          }
        } else {
          _resolvedTitle = null;
        }
        _entries
          ..clear()
          ..addAll(items);
        _reality = reality;
        _ideal = ideal;
        if (resolvedPending) {
          _pendingEntryReady = true;
          if (!streamingActive) {
            _clearPending();
          }
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (showLoading) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      } else {
        setState(() {
          _loading = false;
        });
        _showMessage(e.toString());
      }
    }
  }

  Future<void> _sendFollowup() async {
    if (_submittingFollowup || _pendingQuestion != null) return;
    if (!_canAskMore) {
      _showMessage('최대 $_maxQuestions개 질문까지 가능합니다.');
      return;
    }
    final text = _followupController.text.trim();
    if (text.isEmpty) return;
    if (_reality == null) {
      _showMessage('현실 검사 결과를 찾을 수 없습니다.');
      return;
    }

    setState(() {
      _submittingFollowup = true;
      _pendingQuestion = text;
      _expectedQuestionCount = _questionCount + 1;
      _pendingEntryReady = false;
    });
    _followupController.clear();

    try {
      final realityProfile = _buildProfile(_reality!);
      final idealProfile = _ideal != null
          ? _buildProfile(_ideal!)
          : const _WpiScoreProfile.empty();
      final sources = _buildSources(
        realityResultId: _reality!.result.id,
        idealResultId: _ideal?.result.id,
      );
      final payload = <String, dynamic>{
        'session': {
          'session_id': widget.conversationId,
          'turn': _questionCount + 1,
        },
        'phase': 3,
        'sources': sources,
        'profiles': {
          'reality': realityProfile.toJson(),
          'ideal': idealProfile.toJson(),
        },
        'model': 'gpt-5.2',
        'followup': {'question': text},
      };

      final response = await _repository.interpret(payload);
      if (!mounted) return;
      final responseText = _extractResponseText(response);
      if (responseText.isNotEmpty) {
        _startStreaming(responseText);
      }
      await _load(showLoading: false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _clearPending();
        });
        _showMessage(e.toString());
      } else {
        _clearPending();
      }
    } finally {
      if (mounted) {
        setState(() {
          _submittingFollowup = false;
        });
      } else {
        _submittingFollowup = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text(
          (_resolvedTitle ?? widget.title).trim().isNotEmpty
              ? (_resolvedTitle ?? widget.title).trim()
              : '해석 기록',
        ),
      ),
      bottomNavigationBar: _FollowupInputBar(
        controller: _followupController,
        focusNode: _followupFocus,
        onSend: _sendFollowup,
        enabled:
            !_submittingFollowup && _pendingQuestion == null && _canAskMore,
        sending: _submittingFollowup,
        remaining: _remainingQuestions,
        maxQuestions: _maxQuestions,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? AppErrorView(
                  title: '불러오지 못했어요',
                  message: _error!,
                  primaryActionLabel: AppStrings.retry,
                  primaryActionStyle: AppErrorPrimaryActionStyle.outlined,
                  onPrimaryAction: () => _load(),
                )
              : Builder(
                  builder: (context) {
                    final showProfiles = _reality != null || _ideal != null;
                    final pendingMatchesLast = _pendingQuestion != null &&
                        _pendingEntryReady &&
                        _entries.isNotEmpty;
                    final displayEntryCount =
                        _entries.length - (pendingMatchesLast ? 1 : 0);
                    final totalCount = displayEntryCount +
                        (showProfiles ? 1 : 0) +
                        (_pendingQuestion != null ? 1 : 0);
                    return ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemBuilder: (context, index) {
                        final profileOffset = showProfiles ? 1 : 0;
                        if (showProfiles && index == 0) {
                          return _ConversationProfileSection(
                            reality: _reality,
                            ideal: _ideal,
                          );
                        }
                        final entryIndex = index - profileOffset;
                        if (_pendingQuestion != null &&
                            entryIndex == displayEntryCount) {
                          return _PendingChatExchangeCard(
                            question: _pendingQuestion!,
                            streamingAnswer: _streamingAnswer,
                          );
                        }
                        final resolvedIndex = entryIndex;
                        if (resolvedIndex >= displayEntryCount) {
                          return const SizedBox.shrink();
                        }
                        final entry = _entries[resolvedIndex];
                        if (resolvedIndex == 0 &&
                            _hasCardView(entry.viewModel)) {
                          return _InitialInterpretationRecordSection(
                              entry: entry);
                        }
                        if (resolvedIndex == 0) {
                          return _ConversationEntryCard(entry: entry);
                        }
                        return _ChatExchangeCard(entry: entry);
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemCount: totalCount,
                    );
                  },
                ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _extractResponseText(Map<String, dynamic> response) {
    final interpretationRaw = response['interpretation'];
    if (interpretationRaw is Map) {
      final map = interpretationRaw.cast<String, dynamic>();
      final responseText = (map['response'] ?? '').toString().trim();
      if (responseText.isNotEmpty) return responseText;
      final fallback = (map['title'] ?? '').toString().trim();
      return fallback;
    }
    return interpretationRaw?.toString().trim() ?? '';
  }

  void _startStreaming(String fullText) {
    _streamingTimer?.cancel();
    _streamingFullAnswer = fullText;
    _streamingAnswer = '';
    _streamingIndex = 0;
    final total = fullText.length;
    final step = (total / 300).ceil().clamp(1, 12);
    _streamingTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final nextIndex = (_streamingIndex + step).clamp(0, total);
      setState(() {
        _streamingIndex = nextIndex;
        _streamingAnswer = fullText.substring(0, _streamingIndex);
        if (_streamingIndex >= total && _pendingEntryReady) {
          _clearPending();
        }
      });
      if (_streamingIndex >= total) {
        timer.cancel();
      }
    });
  }

  void _clearPending() {
    _streamingTimer?.cancel();
    _streamingTimer = null;
    _pendingQuestion = null;
    _expectedQuestionCount = null;
    _pendingEntryReady = false;
    _streamingAnswer = null;
    _streamingFullAnswer = null;
    _streamingIndex = 0;
  }
}

class _ConversationEntryCard extends StatelessWidget {
  const _ConversationEntryCard({required this.entry});

  final _ConversationEntry entry;

  @override
  Widget build(BuildContext context) {
    final baseStyle = AppTextStyles.bodySmall
        .copyWith(color: AppColors.textPrimary, height: 1.4);
    final viewModel = entry.viewModel;
    final hasCardView = _hasCardView(viewModel);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.statusLabel,
            style:
                AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text('질문',
              style: AppTextStyles.bodySmall
                  .copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          SelectableText(entry.request, style: baseStyle),
          if (hasCardView ||
              entry.response.isNotEmpty ||
              entry.title.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('응답',
                style: AppTextStyles.bodySmall
                    .copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            if (entry.title.isNotEmpty) ...[
              Text(entry.title,
                  style: baseStyle.copyWith(fontWeight: FontWeight.w700)),
              if (entry.response.isNotEmpty || hasCardView)
                const SizedBox(height: 8),
            ],
            if (hasCardView)
              _InitialInterpretationCardsView(viewModel: viewModel)
            else if (entry.response.isNotEmpty)
              SelectionArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (entry.viewModelMalformed)
                      const _SubtleWarning(
                        text: '카드형 해석을 표시하지 못했어요. 텍스트로 보여드릴게요.',
                      ),
                    MarkdownBody(
                      data: entry.response,
                      styleSheet: MarkdownStyleSheet(
                        p: baseStyle,
                        h1: baseStyle.copyWith(
                            fontSize: 18, fontWeight: FontWeight.w700),
                        h2: baseStyle.copyWith(
                            fontSize: 16, fontWeight: FontWeight.w700),
                        h3: baseStyle.copyWith(
                            fontSize: 14, fontWeight: FontWeight.w700),
                        strong: baseStyle.copyWith(fontWeight: FontWeight.w700),
                        em: baseStyle.copyWith(fontStyle: FontStyle.italic),
                        blockquotePadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
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
                        code: baseStyle.copyWith(
                            fontFamily: 'monospace', fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ChatExchangeCard extends StatelessWidget {
  const _ChatExchangeCard({required this.entry});

  final _ConversationEntry entry;

  @override
  Widget build(BuildContext context) {
    final baseStyle = AppTextStyles.bodySmall
        .copyWith(color: AppColors.textPrimary, height: 1.4);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (entry.statusLabel.trim().isNotEmpty)
            Text(
              entry.statusLabel,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary),
            ),
          const SizedBox(height: 8),
          _ChatBubble(
            text: entry.request,
            isUser: true,
          ),
          const SizedBox(height: 10),
          _ChatBubble(
            isUser: false,
            child: entry.response.isNotEmpty
                ? MarkdownBody(
                    data: entry.response,
                    styleSheet: MarkdownStyleSheet(
                      p: baseStyle,
                      h1: baseStyle.copyWith(
                          fontSize: 18, fontWeight: FontWeight.w700),
                      h2: baseStyle.copyWith(
                          fontSize: 16, fontWeight: FontWeight.w700),
                      h3: baseStyle.copyWith(
                          fontSize: 14, fontWeight: FontWeight.w700),
                      strong: baseStyle.copyWith(fontWeight: FontWeight.w700),
                      em: baseStyle.copyWith(fontStyle: FontStyle.italic),
                      blockquotePadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
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
                      code: baseStyle.copyWith(
                          fontFamily: 'monospace', fontSize: 13),
                    ),
                  )
                : Text(
                    '답변이 아직 도착하지 않았어요.',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PendingChatExchangeCard extends StatelessWidget {
  const _PendingChatExchangeCard({
    required this.question,
    required this.streamingAnswer,
  });

  final String question;
  final String? streamingAnswer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ChatBubble(
            text: question,
            isUser: true,
          ),
          const SizedBox(height: 10),
          _ChatBubble(
            isUser: false,
            child: _buildAnswerBubble(),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerBubble() {
    final answer = streamingAnswer;
    if (answer == null || answer.isEmpty) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(
            '답변 생성 중...',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      );
    }
    return Text(
      answer,
      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    this.text,
    this.child,
    required this.isUser,
  });

  final String? text;
  final Widget? child;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isUser ? AppColors.primary : AppColors.backgroundLight;
    final borderColor = isUser ? AppColors.primary : AppColors.border;
    final textColor = isUser ? Colors.white : AppColors.textPrimary;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: child ??
              Text(
                text ?? '',
                style: AppTextStyles.bodySmall.copyWith(color: textColor),
              ),
        ),
      ),
    );
  }
}

class _ConversationProfileSection extends StatelessWidget {
  const _ConversationProfileSection({
    required this.reality,
    required this.ideal,
  });

  final UserResultDetail? reality;
  final UserResultDetail? ideal;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RealityProfileSection(
          detail: reality,
          selfLabels: _selfKeyLabels,
          otherLabels: _otherKeyLabels,
          selfDisplayLabels: _selfDisplayLabels,
          otherDisplayLabels: _otherDisplayLabels,
        ),
        const SizedBox(height: 24),
        IdealProfileSection(
          detail: ideal,
          selfLabels: _selfKeyLabels,
          otherLabels: _otherKeyLabels,
          selfDisplayLabels: _selfDisplayLabels,
          otherDisplayLabels: _otherDisplayLabels,
        ),
      ],
    );
  }
}

class _FollowupInputBar extends StatelessWidget {
  const _FollowupInputBar({
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.enabled,
    required this.sending,
    required this.remaining,
    required this.maxQuestions,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final bool enabled;
  final bool sending;
  final int remaining;
  final int maxQuestions;

  @override
  Widget build(BuildContext context) {
    final helper = remaining <= 0
        ? '최대 $maxQuestions개 질문까지 가능합니다.'
        : '남은 질문: $remaining/$maxQuestions';
    return SafeArea(
      top: false,
      child: Material(
        color: AppColors.cardBackground,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: AppColors.border),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                helper,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 44),
                      child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        enabled: enabled,
                        minLines: 1,
                        maxLines: 3,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => enabled ? onSend() : null,
                        decoration: const InputDecoration(
                          hintText: '추가로 궁금한 점을 입력하세요.',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: enabled ? onSend : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                    ),
                  ),
                ],
              ),
            ],
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

const _selfKeys = ['realist', 'romantic', 'humanist', 'idealist', 'agent'];
const _standardKeys = ['relation', 'trust', 'manual', 'self', 'culture'];

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

Map<String, double> _fillScores(
  List<String> keys,
  Map<String, double> raw,
) {
  return {for (final key in keys) key: raw[key] ?? 0};
}

String _normalizeKey(String raw) {
  final normalized = raw.toLowerCase().replaceAll(' ', '').split('/').first;
  if (normalized == 'romantist' || normalized == 'romanticist')
    return 'romantic';
  return normalized;
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

String _truncateTitle(String text, {int max = 100}) {
  final normalized = text.trim();
  if (normalized.length <= max) return normalized;
  return '${normalized.substring(0, max)}...';
}

class _ConversationSummary {
  const _ConversationSummary({
    required this.id,
    required this.title,
    required this.firstMessageAt,
    required this.lastMessageAt,
    required this.totalMessages,
  });

  factory _ConversationSummary.fromJson(Map<String, dynamic> json) {
    final title = _readString(
      json,
      keys: const [
        'title',
        'prompt_text',
        'first_prompt_text',
        'request_message',
        'first_request_message',
        'first_message',
        'interpretation_title',
        'conversation_title',
      ],
    );
    return _ConversationSummary(
      id: (json['conversation_id'] ?? json['session_id'] ?? json['id'] ?? '')
          .toString(),
      title: title,
      firstMessageAt: _parseDate(json['first_message_at']?.toString()),
      lastMessageAt: _parseDate(json['last_message_at']?.toString()),
      totalMessages: (json['total_messages'] as int?) ?? 0,
    );
  }

  final String id;
  final String title;
  final DateTime? firstMessageAt;
  final DateTime? lastMessageAt;
  final int totalMessages;

  String get displayTitle => title.trim().isNotEmpty ? title.trim() : '대화 기록';

  String get dateRangeLabel {
    final start = _formatDate(firstMessageAt);
    final end = _formatDate(lastMessageAt);
    if (start.isEmpty && end.isEmpty) return '-';
    if (start == end) return start;
    return '$start ~ $end';
  }

  static DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  static String _readString(
    Map<String, dynamic> json, {
    required List<String> keys,
  }) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      final str = value.toString().trim();
      if (str.isEmpty || str == 'null') continue;
      return str;
    }
    return '';
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}

class _ConversationEntry {
  const _ConversationEntry({
    required this.status,
    required this.request,
    required this.title,
    required this.response,
    required this.viewModel,
    required this.viewModelMalformed,
    required this.createdAt,
    required this.promptText,
    required this.promptKind,
    required this.testIds,
  });

  factory _ConversationEntry.fromJson(Map<String, dynamic> json) {
    final interpretationRaw = json['interpretation'];
    final interpretation = interpretationRaw is Map
        ? interpretationRaw.cast<String, dynamic>()
        : null;
    final rawTitle = _readString(
      interpretation,
      json,
      keys: const ['title', 'interpretation_title', 'conversation_title'],
    );
    final title = rawTitle;
    final response =
        (interpretation?['response'] ?? json['response_message'] ?? '')
            .toString();
    final normalizedResponse = response;
    final viewModelRaw =
        interpretation?['view_model'] ?? interpretation?['viewModel'];
    InitialInterpretationV1? viewModel;
    var viewModelMalformed = false;
    if (viewModelRaw != null) {
      if (viewModelRaw is Map) {
        try {
          viewModel = InitialInterpretationV1.fromJson(
              viewModelRaw.cast<String, dynamic>());
        } catch (_) {
          viewModelMalformed = true;
        }
      } else {
        viewModelMalformed = true;
      }
    }
    final promptText = (json['prompt_text'] ?? '').toString();
    final requestMessage = (json['request_message'] ?? '').toString();
    final resolvedRequest =
        promptText.trim().isNotEmpty ? promptText : requestMessage;
    final promptKind = json['prompt_kind']?.toString();
    final testIds = _readIntList(json['test_ids']);
    return _ConversationEntry(
      status: (json['status'] ?? '').toString(),
      request: resolvedRequest,
      title: title,
      response: normalizedResponse,
      viewModel: viewModel,
      viewModelMalformed: viewModelMalformed,
      createdAt: _parseDate(json['created_at']?.toString()),
      promptText: promptText,
      promptKind: promptKind,
      testIds: testIds,
    );
  }

  final String status;
  final String request;
  final String title;
  final String response;
  final InitialInterpretationV1? viewModel;
  final bool viewModelMalformed;
  final DateTime? createdAt;
  final String promptText;
  final String? promptKind;
  final List<int> testIds;

  String get statusLabel {
    final date = createdAt;
    if (date == null) return status;
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} · $status';
  }

  static DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  static String _readString(
    Map<String, dynamic>? nested,
    Map<String, dynamic> json, {
    required List<String> keys,
  }) {
    for (final key in keys) {
      final value = (nested != null ? nested[key] : null) ?? json[key];
      if (value == null) continue;
      final str = value.toString().trim();
      if (str.isEmpty || str == 'null') continue;
      return str;
    }
    return '';
  }

  static List<int> _readIntList(dynamic value) {
    if (value is List) {
      return value
          .map((e) => int.tryParse(e.toString()) ?? 0)
          .where((e) => e > 0)
          .toList();
    }
    return const [];
  }
}

class _InitialInterpretationCardsView extends StatelessWidget {
  const _InitialInterpretationCardsView({required this.viewModel});

  final InitialInterpretationV1? viewModel;

  @override
  Widget build(BuildContext context) {
    final resolved = viewModel;
    if (resolved == null) return const SizedBox.shrink();

    final headline = resolved.headline.trim();
    final cards = resolved.cards;
    if (headline.isEmpty && cards.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (headline.isNotEmpty) ...[
          _HeadlineCard(headline: headline),
          if (cards.isNotEmpty) const SizedBox(height: 12),
        ],
        ...cards.map(_InterpretationCard.new),
      ],
    );
  }
}

class _InitialInterpretationRecordSection extends StatelessWidget {
  const _InitialInterpretationRecordSection({required this.entry});

  final _ConversationEntry entry;

  @override
  Widget build(BuildContext context) {
    final viewModel = entry.viewModel;
    if (!_hasCardView(viewModel)) {
      return _ConversationEntryCard(entry: entry);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ResultSectionHeader(
          title: '내 마음 해석하기',
          subtitle: '지금 내 마음은 이렇습니다.',
        ),
        const SizedBox(height: 12),
        _InitialInterpretationCardsView(viewModel: viewModel),
      ],
    );
  }
}

class _SubtleWarning extends StatelessWidget {
  const _SubtleWarning({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

class _HeadlineCard extends StatelessWidget {
  const _HeadlineCard({required this.headline});

  final String headline;

  @override
  Widget build(BuildContext context) {
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
}

class _InterpretationCard extends StatelessWidget {
  const _InterpretationCard(this.card);

  final InitialInterpretationCard card;

  @override
  Widget build(BuildContext context) {
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
            style:
                AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            card.summary,
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
          if (bullets.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...bullets.map(
              (bullet) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  '),
                    Expanded(
                      child: Text(
                        bullet,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary),
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
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

bool _hasCardView(InitialInterpretationV1? viewModel) {
  if (viewModel == null) return false;
  return viewModel.cards.isNotEmpty || viewModel.headline.trim().isNotEmpty;
}
