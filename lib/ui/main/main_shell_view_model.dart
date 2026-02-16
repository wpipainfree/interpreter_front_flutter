import 'package:flutter/foundation.dart';

import '../../domain/repository/profile_repository.dart';

class MainShellViewModel extends ChangeNotifier {
  MainShellViewModel(this._profileRepository)
      : _isLoggedIn = _profileRepository.isLoggedIn;

  final ProfileRepository _profileRepository;

  bool _isLoggedIn;
  bool _started = false;

  bool get isLoggedIn => _isLoggedIn;

  void start() {
    if (_started) return;
    _started = true;
    _profileRepository.addAuthListener(_onAuthChanged);
    refreshAuthState(notify: false);
  }

  void refreshAuthState({bool notify = true}) {
    final next = _profileRepository.isLoggedIn;
    if (_isLoggedIn == next) return;
    _isLoggedIn = next;
    if (notify) {
      notifyListeners();
    }
  }

  void _onAuthChanged() {
    refreshAuthState();
  }

  @override
  void dispose() {
    if (_started) {
      _profileRepository.removeAuthListener(_onAuthChanged);
    }
    super.dispose();
  }
}
