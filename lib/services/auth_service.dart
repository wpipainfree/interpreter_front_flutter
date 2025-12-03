/// 임시 인증 서비스 (테스트용)
/// 실제 구현 시 Firebase Auth 또는 백엔드 API로 교체 필요
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // 현재 로그인된 사용자 정보
  UserInfo? _currentUser;
  
  UserInfo? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  /// 이메일/비밀번호 로그인 (임시)
  Future<AuthResult> loginWithEmail(String email, String password) async {
    // 임시 로그인 로직 - 실제로는 서버 인증 필요
    await Future.delayed(const Duration(milliseconds: 500)); // 네트워크 시뮬레이션
    
    // 테스트용: 아무 이메일/비밀번호나 허용
    if (email.contains('@') && password.length >= 6) {
      _currentUser = UserInfo(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        nickname: email.split('@').first,
        provider: 'email',
      );
      return AuthResult.success(_currentUser!);
    }
    
    return AuthResult.failure('이메일 또는 비밀번호가 올바르지 않습니다.');
  }

  /// 소셜 로그인 (임시)
  Future<AuthResult> loginWithSocial(String provider) async {
    await Future.delayed(const Duration(milliseconds: 800)); // 네트워크 시뮬레이션
    
    // 임시 소셜 로그인 - 실제로는 각 플랫폼 SDK 연동 필요
    final providerNames = {
      'kakao': '카카오',
      'naver': '네이버',
      'google': 'Google',
      'facebook': 'Facebook',
    };
    
    final nickname = '${providerNames[provider] ?? provider}사용자';
    
    _currentUser = UserInfo(
      id: '${provider}_${DateTime.now().millisecondsSinceEpoch}',
      email: '$provider@example.com',
      nickname: nickname,
      provider: provider,
      profileImage: null,
    );
    
    return AuthResult.success(_currentUser!);
  }

  /// 회원가입 (임시)
  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String nickname,
    DateTime? birthDate,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!email.contains('@')) {
      return AuthResult.failure('올바른 이메일 형식이 아닙니다.');
    }
    if (password.length < 6) {
      return AuthResult.failure('비밀번호는 6자 이상이어야 합니다.');
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

  /// 로그아웃
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _currentUser = null;
  }

  /// 테스트용 자동 로그인
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

/// 사용자 정보 모델
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

/// 인증 결과
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

