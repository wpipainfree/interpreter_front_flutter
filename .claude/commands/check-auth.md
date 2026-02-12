# 인증 시스템 확인

현재 인증 시스템 구현을 확인합니다.

## 사용법
```
/check-auth
```

## AuthService (`lib/services/auth_service.dart`)

### 주요 메서드

```dart
// 세션
Future<UserInfo?> restoreSession()
bool get isLoggedIn
String? get authorizationHeader

// 이메일 로그인
Future<AuthResult> loginWithEmail(String email, String password)

// 소셜 로그인 → /social-login skill 참조
Future<AuthResult> loginWithSocial(String provider)

// 게스트 로그인
Future<AuthResult> loginAsGuest()

// 로그아웃
Future<void> logout()

// 토큰 갱신
Future<AuthTokens?> refreshAccessToken()
Future<String?> getAuthorizationHeader({bool refreshIfNeeded = true})
```

### 상태 관리

- **싱글톤 패턴**: `AuthService()` 팩토리
- **ChangeNotifier**: 상태 변경 시 `notifyListeners()`
- **저장소**:
  - 모바일: `FlutterSecureStorage`
  - 웹: `SharedPreferences`

### 토큰 구조

```dart
class AuthTokens {
  String accessToken;
  String tokenType;  // 'bearer'
  String? refreshTokenCookie;
  DateTime? accessTokenExpiresAt;
}
```

### 자동 토큰 갱신

- `_refreshBuffer = 60초` 전에 자동 갱신
- 갱신 실패 시 자동 로그아웃 (`LogoutReason.sessionExpired`)

## 백엔드 API

- `POST /api/v1/auth/login` - 이메일 로그인
- `POST /api/v1/auth/logout` - 로그아웃
- `POST /api/v1/auth/refresh` - 토큰 갱신

## 관련 Skill

- `/social-login` - 소셜 로그인 상세
- `/payment` - 결제 시스템 (인증 필요)
