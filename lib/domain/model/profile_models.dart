class ProfileUser {
  const ProfileUser({
    required this.id,
    required this.email,
    required this.name,
    this.provider,
    this.linkedProviders = const [],
    this.counselingClient,
  });

  final String id;
  final String email;
  final String name;
  final String? provider;
  final List<String> linkedProviders;
  final CounselingClientInfo? counselingClient;

  String get displayName {
    if (name.trim().isNotEmpty) return name.trim();
    if (email.contains('@')) return email.split('@').first;
    return email;
  }
}

class CounselingClientInfo {
  const CounselingClientInfo({
    this.clientId,
    this.studentName,
    this.parentName,
    this.grade,
    this.academicTrack,
    this.institutionName,
    this.approvalRole,
    this.isApproved = false,
  });

  final String? clientId;
  final String? studentName;
  final String? parentName;
  final String? grade;
  final String? academicTrack;
  final String? institutionName;
  final String? approvalRole;
  final bool isApproved;
}

class ProfileSocialProviderStatus {
  const ProfileSocialProviderStatus({
    required this.provider,
    required this.providerName,
    required this.isLinked,
    this.email,
    this.nickname,
    this.linkedAt,
  });

  final String provider;
  final String providerName;
  final bool isLinked;
  final String? email;
  final String? nickname;
  final DateTime? linkedAt;
}

class ProfileActionResult {
  const ProfileActionResult({
    required this.isSuccess,
    this.message,
    this.errorMessage,
  });

  final bool isSuccess;
  final String? message;
  final String? errorMessage;
}
