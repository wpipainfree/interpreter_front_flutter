class DashboardUser {
  const DashboardUser({
    required this.id,
    required this.email,
    required this.name,
  });

  final String id;
  final String email;
  final String name;

  String get displayName {
    if (name.trim().isNotEmpty) return name.trim();
    if (email.contains('@')) return email.split('@').first;
    return email;
  }
}

class DashboardAccount {
  const DashboardAccount({
    required this.id,
    required this.userId,
    this.testId,
    this.resultId,
    this.status,
    this.createDate,
    this.modifyDate,
    this.paymentDate,
    this.result,
  });

  final int id;
  final int userId;
  final int? testId;
  final int? resultId;
  final String? status;
  final String? createDate;
  final String? modifyDate;
  final String? paymentDate;
  final Map<String, dynamic>? result;
}

class DashboardRecordSummary {
  const DashboardRecordSummary({
    required this.id,
    required this.title,
    required this.firstMessageAt,
    required this.lastMessageAt,
    required this.totalMessages,
  });

  factory DashboardRecordSummary.fromJson(Map<String, dynamic> json) {
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
    return DashboardRecordSummary(
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

class DashboardPaymentSession {
  const DashboardPaymentSession({
    required this.paymentId,
    required this.webviewUrl,
  });

  final String paymentId;
  final String webviewUrl;
}
