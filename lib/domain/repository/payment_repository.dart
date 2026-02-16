import '../model/payment_models.dart';

abstract interface class PaymentRepository {
  Future<PaymentStatusInfo> getPaymentStatus(int paymentId);

  Future<PaymentHistoryPage> getPaymentHistory({
    int page = 1,
    int pageSize = 20,
  });
}
