import 'package:flutter_test/flutter_test.dart';
import 'package:wpi_app/domain/model/payment_models.dart';
import 'package:wpi_app/ui/profile/payment_history_view_model.dart';

import '../../../testing/fakes/fake_payment_repository.dart';

void main() {
  group('PaymentHistoryViewModel', () {
    test('load fetches first page', () async {
      final fake = FakePaymentRepository()
        ..historyResult = PaymentHistoryPage(
          items: [_item(paymentId: 1)],
          total: 1,
          page: 1,
          pageSize: 20,
          hasMore: false,
        );
      final viewModel = PaymentHistoryViewModel(fake);

      await viewModel.load();

      expect(viewModel.loading, isFalse);
      expect(viewModel.error, isNull);
      expect(viewModel.items.length, 1);
      expect(fake.requestedHistoryPages, [1]);
    });

    test('load sets error when repository throws', () async {
      final fake = FakePaymentRepository()..historyError = Exception('boom');
      final viewModel = PaymentHistoryViewModel(fake);

      await viewModel.load();

      expect(viewModel.loading, isFalse);
      expect(viewModel.error, contains('boom'));
    });

    test('loadMore appends next page items', () async {
      final fake = _PagedPaymentRepository();
      final viewModel = PaymentHistoryViewModel(fake);

      await viewModel.load();
      await viewModel.loadMore();

      expect(viewModel.items.length, 2);
      expect(viewModel.hasMore, isFalse);
      expect(fake.requestedPages, [1, 2]);
    });
  });
}

PaymentHistoryEntry _item({required int paymentId}) {
  return PaymentHistoryEntry(
    paymentId: paymentId,
    amount: 1000,
    status: '2',
    statusText: '완료',
    paymentTypeName: '카드',
    createdAt: DateTime(2026, 2, 16),
  );
}

class _PagedPaymentRepository extends FakePaymentRepository {
  final List<int> requestedPages = [];

  @override
  Future<PaymentHistoryPage> getPaymentHistory({
    int page = 1,
    int pageSize = 20,
  }) async {
    requestedPages.add(page);
    if (page == 1) {
      return PaymentHistoryPage(
        items: [_item(paymentId: 1)],
        total: 2,
        page: 1,
        pageSize: pageSize,
        hasMore: true,
      );
    }
    return PaymentHistoryPage(
      items: [_item(paymentId: 2)],
      total: 2,
      page: 2,
      pageSize: pageSize,
      hasMore: false,
    );
  }
}
