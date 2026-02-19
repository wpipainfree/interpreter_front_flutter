import '../model/psych_test_models.dart';

class ResolveTestStartPermissionUseCase {
  const ResolveTestStartPermissionUseCase();

  TestStartPermission resolve({
    required List<PsychTestAccountSnapshot> accounts,
  }) {
    if (accounts.isEmpty) {
      return const TestStartPermission(
        canStart: false,
        reason: TestStartBlockReason.noEntitlement,
        message: '결제된 검사권이 없습니다. 결제를 완료한 뒤 다시 시도해 주세요.',
      );
    }

    final ordered = List<PsychTestAccountSnapshot>.from(accounts)
      ..sort(_compareByRecentDateDesc);

    final hasAvailable = ordered.any(_isStartAvailable);
    if (hasAvailable) {
      return const TestStartPermission.allowed();
    }

    final resumable = _findResumable(ordered);
    if (resumable != null) {
      return TestStartPermission(
        canStart: false,
        reason: TestStartBlockReason.inProgressResume,
        message: '이미 시작한 검사가 있습니다. 이어하기로 진행해 주세요.',
        resumeResultId: resumable.resultId,
      );
    }

    final hasPendingPayment = ordered.any(
      (account) => _isPendingStatus(account.status),
    );
    if (hasPendingPayment) {
      return const TestStartPermission(
        canStart: false,
        reason: TestStartBlockReason.pendingPayment,
        message: '결제가 아직 완료되지 않았습니다. 결제 상태를 확인해 주세요.',
      );
    }

    final hasCancelledOrRefunded = ordered.any(_isCancelledOrRefunded);
    if (hasCancelledOrRefunded) {
      return const TestStartPermission(
        canStart: false,
        reason: TestStartBlockReason.cancelledOrRefunded,
        message: '환불 또는 취소된 결제건은 검사에 사용할 수 없습니다.',
      );
    }

    return const TestStartPermission(
      canStart: false,
      reason: TestStartBlockReason.noEntitlement,
      message: '사용 가능한 검사권이 없습니다. 결제를 완료한 뒤 다시 시도해 주세요.',
    );
  }

  PsychTestAccountSnapshot? _findResumable(
    List<PsychTestAccountSnapshot> accounts,
  ) {
    for (final account in accounts) {
      if (_isInProgressStatus(account.status) && account.resultId != null) {
        return account;
      }
    }
    return null;
  }

  bool _isStartAvailable(PsychTestAccountSnapshot account) {
    if (_isCancelledOrRefunded(account)) return false;
    if (_isPendingStatus(account.status)) return false;
    if (_isConsumed(account)) return false;

    final status = _normalize(account.status);
    if (_paidStatuses.contains(status)) return true;

    // Some backends store payment completion primarily in payment_date.
    return _normalize(account.paymentDate).isNotEmpty;
  }

  bool _isConsumed(PsychTestAccountSnapshot account) {
    if (account.resultId != null) return true;
    if (_isInProgressStatus(account.status)) return true;
    if (_isCompletedStatus(account.status)) return true;
    if (_isUseFlagUsed(account.useFlag)) return true;
    return false;
  }

  bool _isPendingStatus(String? status) =>
      _pendingStatuses.contains(_normalize(status));

  bool _isInProgressStatus(String? status) =>
      _inProgressStatuses.contains(_normalize(status));

  bool _isCompletedStatus(String? status) =>
      _completedStatuses.contains(_normalize(status));

  bool _isCancelledOrRefunded(PsychTestAccountSnapshot account) {
    final status = _normalize(account.status);
    if (_cancelledStatuses.contains(status)) return true;

    final flag = _normalize(account.useFlag);
    return _cancelledFlags.contains(flag);
  }

  bool _isUseFlagUsed(String? useFlag) =>
      _usedFlags.contains(_normalize(useFlag));

  int _compareByRecentDateDesc(
    PsychTestAccountSnapshot a,
    PsychTestAccountSnapshot b,
  ) {
    final aDate = _parseDate(a.modifyDate) ??
        _parseDate(a.paymentDate) ??
        _parseDate(a.createDate);
    final bDate = _parseDate(b.modifyDate) ??
        _parseDate(b.paymentDate) ??
        _parseDate(b.createDate);

    if (aDate == null && bDate == null) return 0;
    if (aDate == null) return 1;
    if (bDate == null) return -1;
    return bDate.compareTo(aDate);
  }

  DateTime? _parseDate(String? raw) {
    final text = _normalize(raw);
    if (text.isEmpty) return null;
    return DateTime.tryParse(text);
  }

  String _normalize(String? raw) => raw?.trim().toLowerCase() ?? '';

  static const Set<String> _paidStatuses = {
    '2',
    'paid',
    'success',
    'completed',
    'complete',
  };

  static const Set<String> _pendingStatuses = {
    '0',
    '1',
    'pending',
    'ready',
    'waiting',
  };

  static const Set<String> _inProgressStatuses = {
    '3',
    'in_progress',
    'progress',
    'ongoing',
  };

  static const Set<String> _completedStatuses = {
    '4',
    'done',
    'finished',
  };

  static const Set<String> _cancelledStatuses = {
    '5',
    '6',
    '7',
    '8',
    '9',
    'cancelled',
    'canceled',
    'failed',
    'refund',
    'refunded',
    'void',
    'rejected',
  };

  static const Set<String> _usedFlags = {
    'y',
    '1',
    'used',
    'true',
  };

  static const Set<String> _cancelledFlags = {
    'c',
    'r',
    'cancel',
    'cancelled',
    'canceled',
    'refund',
    'refunded',
    'void',
  };
}
