import 'package:flutter/foundation.dart';

import '../../domain/model/profile_models.dart';
import '../../domain/repository/profile_repository.dart';

class MyPageViewModel extends ChangeNotifier {
  MyPageViewModel(this._repository) : _user = _repository.currentUser;

  final ProfileRepository _repository;

  ProfileUser? _user;
  List<ProfileSocialProviderStatus> _socialProviderStatuses = const [];
  bool _isLoadingProviders = false;
  final Map<String, bool> _providerBusyState = {};
  bool _started = false;

  ProfileUser? get user => _user;
  bool get isLoadingProviders => _isLoadingProviders;
  List<ProfileSocialProviderStatus> get socialProviderStatuses =>
      _socialProviderStatuses;

  void start() {
    if (_started) return;
    _started = true;
    _repository.addAuthListener(_onAuthChanged);
    _syncUser(notify: false);
    if (_user != null) {
      loadSocialProviderStatuses();
    }
  }

  Future<void> reloadAfterLogin() async {
    _syncUser();
    if (_user != null) {
      await loadSocialProviderStatuses();
    }
  }

  bool isProviderLinked(String provider) {
    final normalized = provider.toLowerCase();
    final status = _socialProviderStatuses.firstWhere(
      (item) => item.provider.toLowerCase() == normalized,
      orElse: () => ProfileSocialProviderStatus(
        provider: normalized,
        providerName: normalized,
        isLinked: false,
      ),
    );
    return status.isLinked;
  }

  bool isProviderBusy(String provider) {
    return _providerBusyState[provider.toLowerCase()] ?? false;
  }

  Future<void> loadSocialProviderStatuses() async {
    if (_user == null || _isLoadingProviders) return;

    _isLoadingProviders = true;
    notifyListeners();

    try {
      _socialProviderStatuses = await _repository.fetchSocialProviderStatuses();
    } catch (_) {
      _socialProviderStatuses = const [];
    } finally {
      _isLoadingProviders = false;
      notifyListeners();
    }
  }

  Future<ProfileActionResult> linkSocialAccount(String provider) async {
    return _runProviderAction(
      provider: provider,
      action: _repository.linkSocialAccountWithSdk,
    );
  }

  Future<ProfileActionResult> unlinkSocialAccount(String provider) async {
    return _runProviderAction(
      provider: provider,
      action: _repository.unlinkSocialAccount,
    );
  }

  Future<void> logout() => _repository.logout();

  Future<ProfileActionResult> _runProviderAction({
    required String provider,
    required Future<ProfileActionResult> Function(String provider) action,
  }) async {
    final key = provider.toLowerCase();
    if (isProviderBusy(key)) {
      return const ProfileActionResult(
        isSuccess: false,
        errorMessage: '이미 처리 중입니다.',
      );
    }

    _providerBusyState[key] = true;
    notifyListeners();

    try {
      final result = await action(provider);
      if (result.isSuccess) {
        _syncUser(notify: false);
        await loadSocialProviderStatuses();
      }
      return result;
    } finally {
      _providerBusyState[key] = false;
      notifyListeners();
    }
  }

  void _onAuthChanged() {
    final previousUserId = _user?.id;
    _syncUser(notify: false);

    if (_user == null) {
      _socialProviderStatuses = const [];
      _providerBusyState.clear();
      _isLoadingProviders = false;
      notifyListeners();
      return;
    }

    notifyListeners();
    if (_socialProviderStatuses.isEmpty || previousUserId != _user!.id) {
      loadSocialProviderStatuses();
    }
  }

  void _syncUser({bool notify = true}) {
    final nextUser = _repository.currentUser;
    if (_isSameUser(_user, nextUser)) return;
    _user = nextUser;
    if (notify) {
      notifyListeners();
    }
  }

  bool _isSameUser(ProfileUser? left, ProfileUser? right) {
    if (left == null && right == null) return true;
    if (left == null || right == null) return false;
    return left.id == right.id &&
        left.email == right.email &&
        left.name == right.name &&
        left.provider == right.provider &&
        listEquals(left.linkedProviders, right.linkedProviders);
  }

  @override
  void dispose() {
    if (_started) {
      _repository.removeAuthListener(_onAuthChanged);
    }
    super.dispose();
  }
}
