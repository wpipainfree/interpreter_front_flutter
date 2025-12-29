/// 간단한 인메모리 인증 서비스 (샘플용)
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  UserInfo? _currentUser;

  UserInfo? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  Future<AuthResult> loginWithEmail(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (email.contains('@') && password.length >= 6) {
      _currentUser = UserInfo(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        nickname: email.split('@').first,
        provider: 'email',
      );
      return AuthResult.success(_currentUser!);
    }

    return AuthResult.failure('이메일 또는 비밀번호를 다시 확인해주세요.');
  }

  Future<AuthResult> loginWithSocial(String provider) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final providerNames = {
      'kakao': '카카오',
      'naver': '네이버',
      'google': 'Google',
      'facebook': 'Facebook',
    };

    final nickname = '${providerNames[provider] ?? provider} 사용자';

    _currentUser = UserInfo(
      id: '${provider}_${DateTime.now().millisecondsSinceEpoch}',
      email: '$provider@example.com',
      nickname: nickname,
      provider: provider,
      profileImage: null,
    );

    return AuthResult.success(_currentUser!);
  }

  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String nickname,
    DateTime? birthDate,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (!email.contains('@')) {
      return AuthResult.failure('올바른 이메일을 입력해주세요.');
    }
    if (password.length < 6) {
      return AuthResult.failure('비밀번호는 6자 이상 입력해주세요.');
    }

    _currentUser = UserInfo(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      nickname: nickname,
      provider: 'email',
      birthDate: birthDate,
    );

    return AuthResult.success(_currentUser!);
  }

  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _currentUser = null;
  }

  Future<AuthResult> loginAsGuest() async {
    await Future.delayed(const Duration(milliseconds: 300));

    _currentUser = UserInfo(
      id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      email: 'guest@wpi.app',
      nickname: '게스트',
      provider: 'guest',
    );

    return AuthResult.success(_currentUser!);
  }
}

class UserInfo {
  final String id;
  final String email;
  final String nickname;
  final String provider;
  final String? profileImage;
  final DateTime? birthDate;

  const UserInfo({
    required this.id,
    required this.email,
    required this.nickname,
    required this.provider,
    this.profileImage,
    this.birthDate,
  });
}

class AuthResult {
  final bool isSuccess;
  final UserInfo? user;
  final String? errorMessage;

  AuthResult._({
    required this.isSuccess,
    this.user,
    this.errorMessage,
  });

  factory AuthResult.success(UserInfo user) {
    return AuthResult._(isSuccess: true, user: user);
  }

  factory AuthResult.failure(String message) {
    return AuthResult._(isSuccess: false, errorMessage: message);
  }
}
