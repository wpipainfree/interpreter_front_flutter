# 소셜 로그인 시스템

WPI 앱의 소셜 로그인 구현을 확인하고 디버깅합니다.

## 사용법
```
/social-login [provider]
```

## 인자
$ARGUMENTS

- `provider` (선택): kakao, google, apple

## 지원 소셜 로그인

### 1. 카카오 (Kakao)
- **SDK**: `kakao_flutter_sdk_user: ^1.10.0`
- **로그인 플로우**:
  1. 카카오톡 앱 설치 여부 확인
  2. 앱 있으면 `loginWithKakaoTalk()`, 없으면 `loginWithKakaoAccount()`
  3. 받은 access_token을 백엔드로 전달
- **설정 파일**:
  - `lib/main.dart`: `KakaoSdk.init(nativeAppKey: '...')`
  - `android/app/src/main/AndroidManifest.xml`: kakao 스킴
  - `ios/Runner/Info.plist`: URL Scheme

### 2. Google
- **SDK**: `google_sign_in: ^6.2.1`
- **로그인 플로우**:
  1. `GoogleSignIn.signIn()` 호출
  2. id_token과 access_token 획득
  3. 백엔드로 전달
- **설정 파일**:
  - `android/app/google-services.json`
  - `ios/Runner/GoogleService-Info.plist`
  - `ios/Runner/Info.plist`: URL Scheme (REVERSED_CLIENT_ID)

### 3. Apple (iOS only)
- **SDK**: `sign_in_with_apple: ^6.1.3`
- **로그인 플로우**:
  1. `SignInWithApple.getAppleIDCredential()` 호출
  2. id_token과 authorization_code 획득
  3. 백엔드로 전달
- **설정 파일**:
  - `ios/Runner/Runner.entitlements`: Sign In with Apple capability
  - Apple Developer Console 설정

## 프론트엔드 구현

**AuthService 메서드** (`lib/services/auth_service.dart`):

```dart
// 로그인
Future<AuthResult> loginWithSocial(String provider)

// 계정 연동 (로그인된 상태에서)
Future<AuthResult> linkSocialAccountWithSdk(String provider)

// 계정 연동 해제
Future<AuthResult> unlinkSocialAccount(String provider)

// 연동 상태 조회
Future<List<SocialProviderStatus>> getSocialProvidersStatus()
```

## 백엔드 API

- `POST /api/v1/auth/social/token` - 소셜 로그인
- `POST /api/v1/auth/social/link/token` - 계정 연동
- `DELETE /api/v1/auth/social/link/{provider}` - 연동 해제
- `GET /api/v1/auth/social/providers/status` - 상태 조회

## 에러 처리

- **422 USER_NOT_REGISTERED**: 미등록 사용자 → 회원가입 필요
- **409 ALREADY_LINKED**: 이미 다른 계정에 연결된 소셜 계정
- **사용자 취소**: 각 SDK별 취소 감지

## 문서

- [소셜_로그인_설정_가이드.md](docs/소셜_로그인_설정_가이드.md)
- [소셜_로그인_테스트_케이스.md](docs/소셜_로그인_테스트_케이스.md)

## 디버깅

```dart
// AuthService 디버그 로그 확인
// [AuthService] 태그로 필터링
flutter logs | grep AuthService
```
