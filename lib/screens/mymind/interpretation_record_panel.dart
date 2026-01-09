import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../services/ai_assistant_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';

class InterpretationRecordPanel extends StatefulWidget {
  const InterpretationRecordPanel({super.key});

  @override
  State<InterpretationRecordPanel> createState() => _InterpretationRecordPanelState();
}

class _InterpretationRecordPanelState extends State<InterpretationRecordPanel> {
  final AiAssistantService _aiService = AiAssistantService();
  final ScrollController _scrollController = ScrollController();

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
    _scrollController.addListener(_onScroll);
    _loadPage(reset: true);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
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
      final res = await _aiService.fetchConversationSummaries(
        skip: _skip,
        limit: _pageSize,
      );
      final raw = res['conversations'] as List<dynamic>? ?? const [];
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
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
      });
    }
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
              onPressed: () => _loadPage(reset: true),
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

    if (_items.isEmpty) {
      return _infoCard(
        '질문 기록이 없습니다.',
        '해석 탭에서 질문을 보내면 기록 탭에서 다시 확인할 수 있어요.',
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
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                  child: const Text('더 보기'),
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
          Text(subtitle, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
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
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => InterpretationRecordDetailScreen(
              conversationId: item.id,
              title: item.title,
            ),
          ),
        );
      },
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      overlayColor: MaterialStateProperty.all(Colors.transparent),
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
              item.title.isNotEmpty ? item.title : '대화 기록',
              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              item.dateRangeLabel,
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            Text(
              '메시지 ${item.totalMessages}개',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
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
  State<InterpretationRecordDetailScreen> createState() => _InterpretationRecordDetailScreenState();
}

class _InterpretationRecordDetailScreenState extends State<InterpretationRecordDetailScreen> {
  final AiAssistantService _aiService = AiAssistantService();
  bool _loading = true;
  String? _error;
  final List<_ConversationEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _aiService.fetchConversation(widget.conversationId);
      final raw = res['entries'] as List<dynamic>? ?? const [];
      final items = raw.whereType<Map<String, dynamic>>().map(_ConversationEntry.fromJson).toList();
      if (!mounted) return;
      setState(() {
        _entries
          ..clear()
          ..addAll(items);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text(widget.title.isNotEmpty ? widget.title : '해석 기록'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
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
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemBuilder: (context, index) {
                    final entry = _entries[index];
                    return _ConversationEntryCard(entry: entry);
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: _entries.length,
                ),
    );
  }
}

class _ConversationEntryCard extends StatelessWidget {
  const _ConversationEntryCard({required this.entry});

  final _ConversationEntry entry;

  @override
  Widget build(BuildContext context) {
    final baseStyle = AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary, height: 1.4);
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
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text('질문', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          SelectableText(entry.request, style: baseStyle),
          if (entry.response.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('응답', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            SelectionArea(
              child: MarkdownBody(
                data: entry.response,
                styleSheet: MarkdownStyleSheet(
                  p: baseStyle,
                  h1: baseStyle.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
                  h2: baseStyle.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                  h3: baseStyle.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
                  strong: baseStyle.copyWith(fontWeight: FontWeight.w700),
                  em: baseStyle.copyWith(fontStyle: FontStyle.italic),
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
                  code: baseStyle.copyWith(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
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
    return _ConversationSummary(
      id: (json['conversation_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
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

  static String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}

class _ConversationEntry {
  const _ConversationEntry({
    required this.status,
    required this.request,
    required this.response,
    required this.createdAt,
  });

  factory _ConversationEntry.fromJson(Map<String, dynamic> json) {
    return _ConversationEntry(
      status: (json['status'] ?? '').toString(),
      request: (json['request_message'] ?? '').toString(),
      response: (json['response_message'] ?? '').toString(),
      createdAt: _parseDate(json['created_at']?.toString()),
    );
  }

  final String status;
  final String request;
  final String response;
  final DateTime? createdAt;

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
}
