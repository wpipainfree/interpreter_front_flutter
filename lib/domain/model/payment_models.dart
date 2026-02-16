class PaymentStatusInfo {
  const PaymentStatusInfo({
    required this.paymentId,
    required this.status,
    required this.isSuccess,
    required this.isPending,
    required this.isFailed,
    this.errorMessage,
  });

  final int paymentId;
  final String status;
  final bool isSuccess;
  final bool isPending;
  final bool isFailed;
  final String? errorMessage;
}

class PaymentHistoryEntry {
  const PaymentHistoryEntry({
    required this.paymentId,
    required this.amount,
    required this.status,
    required this.statusText,
    required this.paymentTypeName,
    required this.createdAt,
    this.orderId,
    this.testId,
    this.testName,
    this.paymentType,
    this.paymentDate,
  });

  final int paymentId;
  final String? orderId;
  final int? testId;
  final String? testName;
  final int amount;
  final String status;
  final String statusText;
  final int? paymentType;
  final String paymentTypeName;
  final DateTime? paymentDate;
  final DateTime createdAt;

  bool get isCompleted => status == '2';
  bool get isCancelled => status == '5';
}

class PaymentHistoryPage {
  const PaymentHistoryPage({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });

  final List<PaymentHistoryEntry> items;
  final int total;
  final int page;
  final int pageSize;
  final bool hasMore;
}
