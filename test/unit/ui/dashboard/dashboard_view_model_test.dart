import 'package:flutter_test/flutter_test.dart';
import 'package:wpi_app/domain/model/dashboard_models.dart';
import 'package:wpi_app/ui/dashboard/dashboard_view_model.dart';
import 'package:wpi_app/utils/strings.dart';

import '../../../testing/fakes/fake_dashboard_repository.dart';

void main() {
  group('DashboardViewModel', () {
    test('start loads dashboard data when logged in', () async {
      final fake = FakeDashboardRepository()
        ..isLoggedInValue = true
        ..currentUserValue = const DashboardUser(
          id: '1',
          email: 'user@example.com',
          name: 'Tester',
        )
        ..accountsResult = const [
          DashboardAccount(
            id: 10,
            userId: 1,
            testId: 1,
            resultId: 101,
            status: '4',
          ),
        ]
        ..recordsResult = const [
          DashboardRecordSummary(
            id: 'c1',
            title: 'first',
            firstMessageAt: null,
            lastMessageAt: null,
            totalMessages: 2,
          ),
          DashboardRecordSummary(
            id: 'c2',
            title: 'second',
            firstMessageAt: null,
            lastMessageAt: null,
            totalMessages: 4,
          ),
          DashboardRecordSummary(
            id: 'c3',
            title: 'third',
            firstMessageAt: null,
            lastMessageAt: null,
            totalMessages: 6,
          ),
        ]
        ..pendingIdealValue = true;

      final viewModel = DashboardViewModel(fake);
      await viewModel.start();

      expect(viewModel.accountsLoading, isFalse);
      expect(viewModel.recordsLoading, isFalse);
      expect(viewModel.accountsError, isNull);
      expect(viewModel.recordsError, isNull);
      expect(viewModel.accounts.length, 1);
      expect(viewModel.records.length, 3);
      expect(viewModel.recordsHasMore, isTrue);
      expect(viewModel.pendingIdeal, isTrue);
    });

    test('start sets login-required state when logged out', () async {
      final fake = FakeDashboardRepository()
        ..isLoggedInValue = false
        ..currentUserValue = null;
      final viewModel = DashboardViewModel(fake);

      await viewModel.start();

      expect(viewModel.accountsLoading, isFalse);
      expect(viewModel.recordsLoading, isFalse);
      expect(viewModel.accountsError, AppStrings.loginRequired);
      expect(viewModel.recordsError, AppStrings.loginRequired);
      expect(viewModel.accounts, isEmpty);
      expect(viewModel.records, isEmpty);
    });

    test('auth logout event clears data and sets login-required errors',
        () async {
      final fake = FakeDashboardRepository()
        ..isLoggedInValue = true
        ..currentUserValue = const DashboardUser(
          id: '1',
          email: 'user@example.com',
          name: 'Tester',
        )
        ..accountsResult = const [
          DashboardAccount(
            id: 10,
            userId: 1,
            testId: 1,
            resultId: 101,
            status: '4',
          ),
        ]
        ..recordsResult = const [
          DashboardRecordSummary(
            id: 'c1',
            title: 'first',
            firstMessageAt: null,
            lastMessageAt: null,
            totalMessages: 2,
          ),
        ];
      final viewModel = DashboardViewModel(fake);
      await viewModel.start();
      expect(viewModel.accounts, isNotEmpty);
      expect(viewModel.records, isNotEmpty);

      fake
        ..isLoggedInValue = false
        ..currentUserValue = null;
      fake.emitAuthChanged();
      await Future<void>.delayed(Duration.zero);

      expect(viewModel.accounts, isEmpty);
      expect(viewModel.records, isEmpty);
      expect(viewModel.accountsError, AppStrings.loginRequired);
      expect(viewModel.recordsError, AppStrings.loginRequired);
    });

    test('createPayment delegates to repository', () async {
      final fake = FakeDashboardRepository()
        ..isLoggedInValue = true
        ..currentUserValue = const DashboardUser(
          id: '1',
          email: 'user@example.com',
          name: 'Tester',
        )
        ..createPaymentResult = const DashboardPaymentSession(
          paymentId: 'pay_1',
          webviewUrl: 'https://pay.example.com/1',
        );
      final viewModel = DashboardViewModel(fake);

      final created = await viewModel.createPayment(
        userId: 1,
        testId: 1,
        paymentType: 20,
        productName: 'WPI 현실검사',
        buyerName: 'Tester',
        buyerEmail: 'user@example.com',
      );

      expect(created.paymentId, 'pay_1');
      expect(created.webviewUrl, 'https://pay.example.com/1');
    });
  });
}
