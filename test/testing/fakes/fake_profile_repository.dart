import 'package:flutter/foundation.dart';
import 'package:wpi_app/domain/model/profile_models.dart';
import 'package:wpi_app/domain/repository/profile_repository.dart';

class FakeProfileRepository implements ProfileRepository {
  bool isLoggedInValue = false;
  ProfileUser? currentUserValue;

  List<ProfileSocialProviderStatus> providerStatuses = const [];
  ProfileActionResult linkResult = const ProfileActionResult(isSuccess: true);
  ProfileActionResult unlinkResult = const ProfileActionResult(isSuccess: true);

  Object? providerStatusesError;
  Object? linkError;
  Object? unlinkError;
  Object? logoutError;

  final List<VoidCallback> _listeners = [];
  final List<String> linkedProviders = [];
  final List<String> unlinkedProviders = [];
  int logoutCallCount = 0;
  int fetchStatusesCallCount = 0;

  @override
  bool get isLoggedIn => isLoggedInValue;

  @override
  ProfileUser? get currentUser => currentUserValue;

  @override
  void addAuthListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  @override
  void removeAuthListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  @override
  Future<List<ProfileSocialProviderStatus>>
      fetchSocialProviderStatuses() async {
    fetchStatusesCallCount += 1;
    if (providerStatusesError != null) throw providerStatusesError!;
    return providerStatuses;
  }

  @override
  Future<ProfileActionResult> linkSocialAccountWithSdk(String provider) async {
    linkedProviders.add(provider);
    if (linkError != null) throw linkError!;
    return linkResult;
  }

  @override
  Future<ProfileActionResult> unlinkSocialAccount(String provider) async {
    unlinkedProviders.add(provider);
    if (unlinkError != null) throw unlinkError!;
    return unlinkResult;
  }

  @override
  Future<void> logout() async {
    logoutCallCount += 1;
    if (logoutError != null) throw logoutError!;
  }

  void emitAuthChanged() {
    for (final listener in List<VoidCallback>.from(_listeners)) {
      listener();
    }
  }
}
