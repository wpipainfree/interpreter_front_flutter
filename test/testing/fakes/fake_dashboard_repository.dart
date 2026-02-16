import 'package:flutter/foundation.dart';
import 'package:wpi_app/domain/model/dashboard_models.dart';
import 'package:wpi_app/domain/repository/dashboard_repository.dart';

class FakeDashboardRepository implements DashboardRepository {
  bool isLoggedInValue = false;
  DashboardUser? currentUserValue;

  List<DashboardAccount> accountsResult = const [];
  List<DashboardRecordSummary> recordsResult = const [];
  bool pendingIdealValue = false;

  Object? accountsError;
  Object? recordsError;
  Object? pendingIdealError;
  DashboardPaymentSession createPaymentResult = const DashboardPaymentSession(
    paymentId: 'p1',
    webviewUrl: 'https://example.com/pay',
  );
  Object? createPaymentError;

  final List<VoidCallback> _authListeners = [];

  @override
  bool get isLoggedIn => isLoggedInValue;

  @override
  DashboardUser? get currentUser => currentUserValue;

  @override
  void addAuthListener(VoidCallback listener) {
    _authListeners.add(listener);
  }

  @override
  void removeAuthListener(VoidCallback listener) {
    _authListeners.remove(listener);
  }

  @override
  Future<List<DashboardAccount>> fetchRecentAccounts({
    int pageSize = 3,
  }) async {
    if (accountsError != null) throw accountsError!;
    return accountsResult;
  }

  @override
  Future<List<DashboardRecordSummary>> fetchRecentRecords({
    int limit = 3,
  }) async {
    if (recordsError != null) throw recordsError!;
    return recordsResult;
  }

  @override
  Future<bool> hasPendingIdeal() async {
    if (pendingIdealError != null) throw pendingIdealError!;
    return pendingIdealValue;
  }

  @override
  Future<DashboardPaymentSession> createPayment({
    required int userId,
    required int testId,
    required int paymentType,
    required String productName,
    required String buyerName,
    required String buyerEmail,
    String buyerTel = '01000000000',
  }) async {
    if (createPaymentError != null) throw createPaymentError!;
    return createPaymentResult;
  }

  void emitAuthChanged() {
    for (final listener in List<VoidCallback>.from(_authListeners)) {
      listener();
    }
  }
}
