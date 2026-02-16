import 'package:flutter/foundation.dart';

import '../model/profile_models.dart';

abstract interface class ProfileRepository {
  bool get isLoggedIn;

  ProfileUser? get currentUser;

  void addAuthListener(VoidCallback listener);

  void removeAuthListener(VoidCallback listener);

  Future<List<ProfileSocialProviderStatus>> fetchSocialProviderStatuses();

  Future<ProfileActionResult> linkSocialAccountWithSdk(String provider);

  Future<ProfileActionResult> unlinkSocialAccount(String provider);

  Future<void> logout();
}
