import 'package:flutter/foundation.dart';

import '../model/dashboard_models.dart';

abstract interface class DashboardRepository {
  bool get isLoggedIn;

  DashboardUser? get currentUser;

  void addAuthListener(VoidCallback listener);

  void removeAuthListener(VoidCallback listener);

  Future<List<DashboardAccount>> fetchRecentAccounts({
    int pageSize = 3,
  });

  Future<List<DashboardRecordSummary>> fetchRecentRecords({
    int limit = 3,
  });

  Future<bool> hasPendingIdeal();

  Future<DashboardPaymentSession> createPayment({
    required int userId,
    required int testId,
    required int paymentType,
    required String productName,
    required String buyerName,
    required String buyerEmail,
    String buyerTel = '01000000000',
  });
}
