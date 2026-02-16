import '../../domain/model/payment_models.dart';
import '../../domain/repository/payment_repository.dart';
import '../../services/payment_service.dart' as payment;

class PaymentRepositoryImpl implements PaymentRepository {
  PaymentRepositoryImpl({payment.PaymentService? paymentService})
      : _paymentService = paymentService ?? payment.PaymentService();

  final payment.PaymentService _paymentService;

  @override
  Future<PaymentStatusInfo> getPaymentStatus(int paymentId) async {
    final raw = await _paymentService.getPaymentStatus(paymentId);
    return PaymentStatusInfo(
      paymentId: raw.paymentId,
      status: raw.status,
      isSuccess: raw.isSuccess,
      isPending: raw.isPending,
      isFailed: raw.isFailed,
      errorMessage: raw.errorMessage,
    );
  }

  @override
  Future<PaymentHistoryPage> getPaymentHistory({
    int page = 1,
    int pageSize = 20,
  }) async {
    final raw = await _paymentService.getPaymentHistory(
      page: page,
      pageSize: pageSize,
    );
    return PaymentHistoryPage(
      items: raw.items.map(_mapHistoryItem).toList(),
      total: raw.total,
      page: raw.page,
      pageSize: raw.pageSize,
      hasMore: raw.hasMore,
    );
  }

  PaymentHistoryEntry _mapHistoryItem(payment.PaymentHistoryItem item) {
    return PaymentHistoryEntry(
      paymentId: item.paymentId,
      orderId: item.orderId,
      testId: item.testId,
      testName: item.testName,
      amount: item.amount,
      status: item.status,
      statusText: item.statusText,
      paymentType: item.paymentType,
      paymentTypeName: item.paymentTypeName,
      paymentDate: item.paymentDate,
      createdAt: item.createdAt,
    );
  }
}
