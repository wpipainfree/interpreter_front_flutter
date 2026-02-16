import 'package:wpi_app/domain/model/payment_models.dart';
import 'package:wpi_app/domain/repository/payment_repository.dart';

class FakePaymentRepository implements PaymentRepository {
  PaymentStatusInfo paymentStatusResult = const PaymentStatusInfo(
    paymentId: 1,
    status: '2',
    isSuccess: true,
    isPending: false,
    isFailed: false,
  );
  PaymentHistoryPage historyResult = const PaymentHistoryPage(
    items: [],
    total: 0,
    page: 1,
    pageSize: 20,
    hasMore: false,
  );

  Object? paymentStatusError;
  Object? historyError;

  final List<int> requestedHistoryPages = [];

  @override
  Future<PaymentStatusInfo> getPaymentStatus(int paymentId) async {
    if (paymentStatusError != null) throw paymentStatusError!;
    return paymentStatusResult;
  }

  @override
  Future<PaymentHistoryPage> getPaymentHistory({
    int page = 1,
    int pageSize = 20,
  }) async {
    requestedHistoryPages.add(page);
    if (historyError != null) throw historyError!;
    return historyResult;
  }
}
