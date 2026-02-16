import 'package:flutter/foundation.dart';

import '../../domain/model/profile_models.dart' as domain;
import '../../domain/repository/profile_repository.dart';
import '../../services/auth_service.dart' as auth;

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({auth.AuthService? authService})
      : _authService = authService ?? auth.AuthService();

  final auth.AuthService _authService;

  @override
  bool get isLoggedIn => _authService.isLoggedIn;

  @override
  domain.ProfileUser? get currentUser {
    final raw = _authService.currentUser;
    if (raw == null) return null;
    return _mapUser(raw);
  }

  @override
  void addAuthListener(VoidCallback listener) {
    _authService.addListener(listener);
  }

  @override
  void removeAuthListener(VoidCallback listener) {
    _authService.removeListener(listener);
  }

  @override
  Future<List<domain.ProfileSocialProviderStatus>>
      fetchSocialProviderStatuses() async {
    final raw = await _authService.getSocialProvidersStatus();
    return raw.map(_mapProviderStatus).toList();
  }

  @override
  Future<domain.ProfileActionResult> linkSocialAccountWithSdk(
    String provider,
  ) async {
    final raw = await _authService.linkSocialAccountWithSdk(provider);
    return domain.ProfileActionResult(
      isSuccess: raw.isSuccess,
      message: raw.successMessage,
      errorMessage: raw.errorMessage,
    );
  }

  @override
  Future<domain.ProfileActionResult> unlinkSocialAccount(
      String provider) async {
    final raw = await _authService.unlinkSocialAccount(provider);
    return domain.ProfileActionResult(
      isSuccess: raw.isSuccess,
      message: raw.successMessage,
      errorMessage: raw.errorMessage,
    );
  }

  @override
  Future<void> logout() => _authService.logout();

  domain.ProfileUser _mapUser(auth.UserInfo raw) {
    return domain.ProfileUser(
      id: raw.id,
      email: raw.email,
      name: raw.name,
      provider: raw.provider,
      linkedProviders: raw.linkedProviders,
      counselingClient: _mapCounselingClient(raw.counselingClient),
    );
  }

  domain.CounselingClientInfo? _mapCounselingClient(
    auth.CounselingClient? raw,
  ) {
    if (raw == null) return null;
    return domain.CounselingClientInfo(
      clientId: raw.clientId,
      studentName: raw.studentName,
      parentName: raw.parentName,
      grade: raw.grade,
      academicTrack: raw.academicTrack,
      institutionName: raw.institutionName,
      approvalRole: raw.approvalRole,
      isApproved: raw.isApproved,
    );
  }

  domain.ProfileSocialProviderStatus _mapProviderStatus(
    auth.SocialProviderStatus raw,
  ) {
    return domain.ProfileSocialProviderStatus(
      provider: raw.provider,
      providerName: raw.providerName,
      isLinked: raw.isLinked,
      email: raw.email,
      nickname: raw.nickname,
      linkedAt: raw.linkedAt,
    );
  }
}
