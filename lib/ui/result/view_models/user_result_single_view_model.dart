import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../domain/model/result_models.dart';
import '../../../domain/repository/result_repository.dart';
import '../../../utils/strings.dart';

class UserResultSingleViewModel extends ChangeNotifier {
  UserResultSingleViewModel(
    this._repository, {
    required this.resultId,
    this.testId,
  });

  final ResultRepository _repository;
  final int resultId;
  final int? testId;

  bool _loading = true;
  String? _error;
  UserResultDetail? _detail;
  bool _started = false;

  bool _lastLoggedIn = false;
  String? _lastUserId;

  bool get loading => _loading;
  String? get error => _error;
  UserResultDetail? get detail => _detail;
  bool get isLoggedIn => _repository.isLoggedIn;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    _lastLoggedIn = _repository.isLoggedIn;
    _lastUserId = _repository.currentUserId;
    _repository.addAuthListener(_handleAuthChanged);
    await load();
  }

  void stop() {
    if (!_started) return;
    _repository.removeAuthListener(_handleAuthChanged);
    _started = false;
  }

  Future<void> reloadAfterLogin() => load();

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    if (!_repository.isLoggedIn) {
      _detail = null;
      _loading = false;
      _error = AppStrings.loginRequired;
      notifyListeners();
      return;
    }

    try {
      final result = await _repository.fetchResultDetail(resultId);
      _detail = result;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void _handleAuthChanged() {
    final nowLoggedIn = _repository.isLoggedIn;
    final nowUserId = _repository.currentUserId;
    if (nowLoggedIn == _lastLoggedIn && nowUserId == _lastUserId) return;

    _lastLoggedIn = nowLoggedIn;
    _lastUserId = nowUserId;

    if (nowLoggedIn) {
      unawaited(load());
      return;
    }

    _detail = null;
    _loading = false;
    _error = AppStrings.loginRequired;
    notifyListeners();
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
