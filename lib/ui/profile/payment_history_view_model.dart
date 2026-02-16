import 'package:flutter/foundation.dart';

import '../../domain/model/payment_models.dart';
import '../../domain/repository/payment_repository.dart';

class PaymentHistoryViewModel extends ChangeNotifier {
  PaymentHistoryViewModel(this._repository);

  final PaymentRepository _repository;
  final List<PaymentHistoryEntry> _items = [];

  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _error;

  List<PaymentHistoryEntry> get items => _items;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;

  Future<void> start() => load();

  Future<void> refresh() => load();

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _repository.getPaymentHistory(page: 1);
      _items
        ..clear()
        ..addAll(response.items);
      _currentPage = 1;
      _hasMore = response.hasMore;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore) return;

    _loadingMore = true;
    notifyListeners();

    try {
      final response = await _repository.getPaymentHistory(
        page: _currentPage + 1,
      );
      _items.addAll(response.items);
      _currentPage = response.page;
      _hasMore = response.hasMore;
    } catch (_) {
      // Pagination errors are ignored to keep current data visible.
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }
}
