import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/model/dashboard_models.dart';
import '../../domain/repository/dashboard_repository.dart';
import '../../utils/strings.dart';

class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel(this._repository);

  static const int maxRecent = 3;
  static const int maxRecordPreview = 3;

  final DashboardRepository _repository;

  final List<DashboardAccount> _accounts = [];
  final List<DashboardRecordSummary> _records = [];

  bool _accountsLoading = true;
  bool _recordsLoading = true;
  bool _recordsHasMore = false;
  bool _pendingIdeal = false;
  String? _accountsError;
  String? _recordsError;
  bool _started = false;

  bool _lastLoggedIn = false;
  String? _lastUserId;

  List<DashboardAccount> get accounts => _accounts;
  List<DashboardRecordSummary> get records => _records;
  bool get accountsLoading => _accountsLoading;
  bool get recordsLoading => _recordsLoading;
  bool get recordsHasMore => _recordsHasMore;
  bool get pendingIdeal => _pendingIdeal;
  String? get accountsError => _accountsError;
  String? get recordsError => _recordsError;

  bool get isLoggedIn => _repository.isLoggedIn;
  DashboardUser? get currentUser => _repository.currentUser;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    _lastLoggedIn = isLoggedIn;
    _lastUserId = currentUser?.id;
    _repository.addAuthListener(_handleAuthChanged);
    await loadAccounts();
    await loadRecords();
    await loadPendingIdeal();
  }

  void stop() {
    if (!_started) return;
    _repository.removeAuthListener(_handleAuthChanged);
    _started = false;
  }

  Future<void> reloadAfterLogin() async {
    await loadAccounts();
    await loadRecords();
  }

  Future<void> loadAccounts() async {
    final userId = (currentUser?.id ?? '').trim();
    if (userId.isEmpty) {
      _accounts.clear();
      _accountsLoading = false;
      _accountsError = AppStrings.loginRequired;
      notifyListeners();
      return;
    }

    _accountsLoading = true;
    _accountsError = null;
    notifyListeners();

    try {
      final fetched = await _repository.fetchRecentAccounts(
        pageSize: maxRecent,
      );
      _accounts
        ..clear()
        ..addAll(fetched);
      _accountsLoading = false;
      _accountsError = null;
    } catch (e) {
      _accountsLoading = false;
      _accountsError = e.toString();
    }
    notifyListeners();
  }

  Future<void> loadRecords() async {
    if (!isLoggedIn) {
      _records.clear();
      _recordsLoading = false;
      _recordsHasMore = false;
      _recordsError = AppStrings.loginRequired;
      notifyListeners();
      return;
    }

    _recordsLoading = true;
    _recordsError = null;
    notifyListeners();

    try {
      final fetched = await _repository.fetchRecentRecords(
        limit: maxRecordPreview,
      );
      _records
        ..clear()
        ..addAll(fetched);
      _recordsHasMore = fetched.length == maxRecordPreview;
      _recordsLoading = false;
      _recordsError = null;
    } catch (e) {
      _recordsLoading = false;
      _recordsError = e.toString();
    }
    notifyListeners();
  }

  Future<void> loadPendingIdeal() async {
    _pendingIdeal = await _repository.hasPendingIdeal();
    notifyListeners();
  }

  Future<DashboardPaymentSession> createPayment({
    required int userId,
    required int testId,
    required int paymentType,
    required String productName,
    required String buyerName,
    required String buyerEmail,
    String buyerTel = '01000000000',
  }) {
    return _repository.createPayment(
      userId: userId,
      testId: testId,
      paymentType: paymentType,
      productName: productName,
      buyerName: buyerName,
      buyerEmail: buyerEmail,
      buyerTel: buyerTel,
    );
  }

  void _handleAuthChanged() {
    final nowLoggedIn = isLoggedIn;
    final nowUserId = currentUser?.id;
    if (nowLoggedIn == _lastLoggedIn && nowUserId == _lastUserId) return;

    _lastLoggedIn = nowLoggedIn;
    _lastUserId = nowUserId;

    if (!nowLoggedIn) {
      _accounts.clear();
      _accountsLoading = false;
      _accountsError = AppStrings.loginRequired;
      _records.clear();
      _recordsLoading = false;
      _recordsHasMore = false;
      _recordsError = AppStrings.loginRequired;
      notifyListeners();
      return;
    }

    unawaited(loadAccounts());
    unawaited(loadRecords());
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
