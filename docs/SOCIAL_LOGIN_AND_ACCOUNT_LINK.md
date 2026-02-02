# 소셜 로그인 및 계정 연동 작업 정리 (상세)

WPI 앱에 적용된 소셜 로그인(카카오, Google, Apple) 및 소셜 계정 연동 관련 구현을 **상세**히 정리한 문서입니다.

---

## 목차

1. [개요 및 전체 흐름](#1-개요-및-전체-흐름)
2. [의존성](#2-의존성-pubspecyaml)
3. [로그인 화면 소셜 로그인](#3-로그인-화면-소셜-로그인)
4. [AuthService 소셜 로그인 상세](#4-authservice-소셜-로그인-상세)
5. [앱 진입점 (main.dart)](#5-앱-진입점-maindart)
6. [Android 설정](#6-android-설정)
7. [백엔드 API 상세](#7-백엔드-api-상세)
8. [소셜 계정 연동 (선택)](#8-소셜-계정-연동-선택)
9. [빌드 및 실행](#9-빌드-및-실행)
10. [트러블슈팅 상세](#10-트러블슈팅-상세)
11. [발생한 에러 및 수정 내역](#11-발생한-에러-및-수정-내역)
12. [수정/추가된 파일 목록](#12-수정추가된-파일-목록)

---

## 1. 개요 및 전체 흐름

### 1.1 목적

- **로그인 화면**에서 카카오 / Apple / Google 버튼을 누르면 각 제공자 SDK로 인증 후, 백엔드에서 우리 서비스 JWT를 발급받아 로그인 완료.
- **Android**에서는 카카오 인증 후 브라우저/카카오톡에서 앱으로 돌아올 수 있도록 **리다이렉트 URI**를 앱에서 처리해야 함.

### 1.2 전체 시퀀스 (카카오 예시)

```
[사용자] 로그인 화면에서 "카카오로 계속하기" 탭
    → [LoginScreen] _handleSocialLogin('kakao') 호출
    → [AuthService] loginWithSocial('kakao') → _loginWithKakaoSdk()
    → [Kakao SDK] loginWithKakaoTalk() 또는 loginWithKakaoAccount()
        → Custom Tabs(Chrome) 또는 카카오톡 앱에서 로그인/동의 화면 표시
        → 사용자가 "계속하기" 클릭
        → 카카오가 redirect: kakaoa531a4604dfddd5837c464cc44053e5d://oauth?code=xxx
    → [Android] intent-filter로 위 URI 수신 → MainActivity 복귀
    → [Kakao SDK] authorization code로 access_token 획득
    → [AuthService] _exchangeSocialToken('kakao', accessToken: token)
    → [백엔드] POST /api/v1/auth/social/token → JWT + 사용자 정보 반환
    → [AuthService] _handleSocialLoginResponse() → 세션 저장, notifyListeners
    → [LoginScreen] _completeAuth(success: true) → Navigator.pop → 메인 화면으로 이동
```

### 1.3 왜 Android에서 "앱으로 안 돌아오는" 문제가 생기는가

- 카카오가 로그인/동의 완료 후 **리다이렉트 URI**로 이동시킴. (예: `kakaoa531a4604dfddd5837c464cc44053e5d://oauth?code=...`)
- Android는 이 URI를 **어떤 앱이 처리할지** `AndroidManifest.xml`의 **intent-filter**로 결정함.
- 우리 앱의 **MainActivity**에 해당 scheme/host에 대한 intent-filter가 없으면, 시스템이 우리 앱을 열지 않아서 **브라우저/카카오 화면에 머무르거나 에러**가 남.
- 따라서 **MainActivity에 카카오 OAuth용 intent-filter를 추가**하고, **Manifest 변경 후에는 반드시 클린 빌드**가 필요함.

---

## 2. 의존성 (pubspec.yaml)

### 2.1 추가된 패키지

```yaml
# 소셜 로그인 SDK
kakao_flutter_sdk_user: ^1.9.5
google_sign_in: ^6.2.1
sign_in_with_apple: ^6.1.3
app_links: ^7.0.0
```

### 2.2 각 패키지 역할 (상세)

| 패키지 | 역할 | 비고 |
|--------|------|------|
| **kakao_flutter_sdk_user** | 카카오 로그인. `loginWithKakaoTalk()`(카카오톡 앱), `loginWithKakaoAccount()`(웹 계정 로그인) 제공. 인증 후 access_token 반환. | Android에서 리다이렉트 받으려면 intent-filter 필수. |
| **google_sign_in** | Google 로그인. `GoogleSignIn().signIn()` 후 `authentication.accessToken` / `idToken` 획득. | Android는 google-services.json, iOS는 URL Scheme 등 설정 필요. |
| **sign_in_with_apple** | Apple 로그인. `SignInWithApple.getAppleIDCredential()`로 `identityToken` 획득. | **iOS/macOS에서만** 동작. Android에서는 "Apple 로그인은 iOS/macOS에서만 지원됩니다" 메시지 반환. |
| **app_links** | 딥링크/앱링크 수신. 수동 OAuth(예: 웹뷰에서 코드 받기) 구현 시 사용. | 현재 로그인 흐름에서는 Kakao SDK가 리다이렉트를 처리하므로 필수는 아님. |

---

## 3. 로그인 화면 소셜 로그인

### 3.1 Feature Flag (lib/utils/feature_flags.dart)

- **의미**: 소셜 로그인 버튼을 **표시할지 여부**를 빌드 시점/환경 변수로 제어.
- **코드**:
  ```dart
  static const bool enableSocialLogin = bool.fromEnvironment(
    'WPI_ENABLE_SOCIAL_LOGIN',
    defaultValue: true,  // 기본값 true → 버튼 표시
  );
  ```
- **동작**:
  - `defaultValue: true` → dart-define 없이 빌드해도 소셜 버튼 표시.
  - 소셜 버튼을 숨기려면: `flutter run --dart-define=WPI_ENABLE_SOCIAL_LOGIN=false`

### 3.2 로그인 화면 UI (lib/screens/auth/login_screen.dart)

- **조건**: `FeatureFlags.enableSocialLogin == true` 일 때만 소셜 버튼 블록 렌더링.
- **버튼 구성**:
  - 카카오로 계속하기 → `_handleSocialLogin('kakao')`
  - Apple로 계속하기 → `_handleSocialLogin('apple')`
  - Google로 계속하기 → `_handleSocialLogin('google')`
- **로딩 중**: `_isLoading == true` 이면 모든 소셜 버튼 `onPressed: null` 로 비활성화.
- **에러**: `_errorMessage` 가 있으면 `_ErrorBanner` 로 표시 (예: "카카오 로그인에 실패했습니다.").

### 3.3 _handleSocialLogin 동작

1. `setState` 로 `_isLoading = true`, `_errorMessage = null` 설정.
2. `_authService.loginWithSocial(provider)` 호출 (비동기).
3. `result.isSuccess` 이면 `_completeAuth(success: true)` → `Navigator.pop(context, true)` 로 로그인 완료 후 메인으로 복귀.
4. 실패 시 `_errorMessage` / `_debugMessage` 설정 후 배너에 표시.

---

## 4. AuthService 소셜 로그인 상세

**파일**: `lib/services/auth_service.dart`

### 4.1 loginWithSocial(provider)

- **역할**: provider 문자열(`kakao` / `google` / `apple`)에 따라 해당 SDK 로그인 메서드로 분기.
- **코드 흐름**:
  - `provider.toLowerCase()` 후 `switch`
  - `kakao` → `_loginWithKakaoSdk()`
  - `google` → `_loginWithGoogleSdk()`
  - `apple` → `_loginWithAppleSdk()`
  - 그 외 → `AuthResult.failure('지원하지 않는 로그인 방식입니다.')`
- **예외**: 상위 `try/catch`에서 예외 시 `AuthResult.failure('소셜 로그인 중 오류가 발생했습니다.')` 반환.

### 4.2 _loginWithKakaoSdk()

- **1단계**: `kakao.isKakaoTalkInstalled()` 로 카카오톡 설치 여부 확인.
- **2단계**:
  - 설치됨: `UserApi.instance.loginWithKakaoTalk()` 시도. 실패 시(예: 사용자 취소, 환경 오류) `loginWithKakaoAccount()` 로 폴백.
  - 미설치: `UserApi.instance.loginWithKakaoAccount()` 만 사용 (웹뷰/브라우저 로그인).
- **3단계**: `OAuthToken.accessToken` 획득 후 `_exchangeSocialToken('kakao', accessToken: token.accessToken)` 호출.
- **실패 시**: `AuthResult.failure('카카오 로그인에 실패했습니다.')` 반환.

### 4.3 _loginWithGoogleSdk()

- `GoogleSignIn(scopes: ['email', 'profile'])` 로 `signIn()` 호출.
- 사용자가 취소하면 `account == null` → `AuthResult.failure('Google 로그인이 취소되었습니다.')`.
- `account.authentication` 에서 `accessToken`, `idToken` 획득. 둘 다 없으면 실패 메시지 반환.
- 성공 시 `_exchangeSocialToken('google', accessToken: accessToken, idToken: idToken)` 호출.

### 4.4 _loginWithAppleSdk()

- `Platform.isIOS || Platform.isMacOS` 가 아니면 곧바로 `AuthResult.failure('Apple 로그인은 iOS/macOS에서만 지원됩니다.')` 반환.
- `SignInWithApple.getAppleIDCredential()` 로 이메일/풀네임 스코프 요청.
- `credential.identityToken` 이 없으면 실패.
- 있으면 `_exchangeSocialToken('apple', idToken: idToken)` 호출 (Apple은 id_token만 전달).

### 4.5 _exchangeSocialToken(provider, accessToken?, idToken?)

- **역할**: 소셜 제공자에서 받은 토큰을 우리 백엔드로 보내서 **우리 서비스용 JWT**를 받고, 그 결과로 로그인 세션을 만듦.
- **요청**:
  - URL: `_uri('/api/v1/auth/social/token')` (예: `http://10.0.2.2:9500/api/v1/auth/social/token`)
  - Method: `POST`
  - Content-Type: `application/json`
  - Body: `provider`, `access_token`(있을 때), `id_token`(있을 때), `include_refresh_token: true`
- **성공 시**: `response.statusCode == 200` 이면 `_asJsonMap(response.data)` 와 `set-cookie`(리프레시 토큰)를 `_handleSocialLoginResponse(data, refreshCookie)` 에 넘김.
- **실패 시**: 404면 "소셜 로그인 API를 찾을 수 없습니다.", 그 외 네트워크/서버 오류는 "서버 연결에 실패했습니다." 등으로 `AuthResult.failure` 반환.

### 4.6 _handleSocialLoginResponse(data, refreshCookie)

- **역할**: 백엔드 응답으로 `UserInfo`와 `AuthTokens`를 만들고, 메모리·로컬 저장소에 세션 저장.
- **처리 내용**:
  - `UserInfo.fromJson(data)` 로 사용자 정보 생성.
  - `AuthTokens(accessToken, tokenType, refreshTokenCookie, accessTokenExpiresAt)` 생성. `expires_in` 이 있으면 `DateTime.now().add(Duration(seconds: data['expires_in']))` 로 만료 시각 설정.
  - `_currentUser`, `_tokens` 갱신, `_lastLogoutReason = null`, `notifyListeners()` 호출.
  - `_persistSession(user, tokens)` 로 secure storage / shared_preferences 에 저장.
- **반환**: `AuthResult.success(user)`.

---

## 5. 앱 진입점 (main.dart)

### 5.1 Kakao SDK 초기화

- **시점**: `WidgetsFlutterBinding.ensureInitialized()` 직후, 다른 초기화보다 먼저 수행하는 것을 권장.
- **코드**: `kakao.KakaoSdk.init(nativeAppKey: 'a531a4604dfddd5837c464cc44053e5d');`
- **이유**: 카카오 로그인/API 호출 전에 네이티브 앱 키가 설정돼 있어야 함.

### 5.2 Android Key Hash 로그 (디버그용)

- **코드**: `kIsWeb == false` 일 때 `KakaoSdk.origin` 을 호출해 키 해시를 얻고, `debugPrint` 로 출력.
- **목적**: 카카오 개발자 콘솔 → Android 플랫폼에 **키 해시**를 등록해야 로그인이 동작함. 앱 실행 시 로그에 출력되는 값을 그대로 등록하면 됨. (예: `rDJagr1HbOCPgRx0VvX+MQMxzgY=`)

---

## 6. Android 설정

### 6.1 AndroidManifest.xml – 카카오 OAuth 리다이렉트

- **위치**: `android/app/src/main/AndroidManifest.xml` 의 **MainActivity** 안에 다른 intent-filter와 함께 추가.
- **전체 intent-filter 블록 예시**:
  ```xml
  <!-- Kakao OAuth redirect: kakao{NATIVE_APP_KEY}://oauth -->
  <intent-filter>
      <action android:name="android.intent.action.VIEW"/>
      <category android:name="android.intent.category.DEFAULT"/>
      <category android:name="android.intent.category.BROWSABLE"/>
      <data android:scheme="kakaoa531a4604dfddd5837c464cc44053e5d" android:host="oauth"/>
  </intent-filter>
  ```
- **의미**:
  - 카카오가 로그인/동의 완료 후 `kakaoa531a4604dfddd5837c464cc44053e5d://oauth?code=xxx` 로 리다이렉트함.
  - Android가 이 URI를 받으면 위 intent-filter가 있는 **MainActivity**를 띄움 → 앱으로 복귀.
  - Kakao SDK가 이 intent를 받아 authorization code를 추출하고, 내부적으로 access_token 교환 후 우리가 호출한 `loginWithKakaoTalk()` / `loginWithKakaoAccount()` Future가 완료됨.

### 6.2 Manifest 변경 후 반드시 할 일

- **핫 리로드/핫 리스타트만으로는 Manifest 변경이 반영되지 않음.**
- 다음 순서로 **클린 빌드** 후 다시 실행:
  ```bash
  flutter clean
  flutter pub get
  flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:9500
  ```

### 6.3 카카오 개발자 콘솔 설정

- **사이트**: [Kakao Developers](https://developers.kakao.com) → 해당 앱 선택.
- **카카오 로그인** 메뉴에서:
  1. **Redirect URI**에 `kakaoa531a4604dfddd5837c464cc44053e5d://oauth` **정확히** 등록.
  2. **Android** 플랫폼 추가 후 **키 해시** 등록 (앱 실행 시 로그에 출력되는 값, 예: `rDJagr1HbOCPgRx0VvX+MQMxzgY=`).
- 이렇게 해야 카카오가 우리 앱을 신뢰하고 리다이렉트를 허용함.

---

## 7. 백엔드 API 상세

### 7.1 소셜 로그인 토큰 교환

- **Method**: `POST`
- **URL**: `{API_BASE_URL}/api/v1/auth/social/token` (예: `http://10.0.2.2:9500/api/v1/auth/social/token`)
- **Content-Type**: `application/json`
- **Request Body**:
  - `provider` (필수): `"kakao"` | `"google"` | `"apple"`
  - `access_token` (선택): 카카오/구글 액세스 토큰. Apple은 보통 id_token만 사용.
  - `id_token` (선택): 구글/애플 ID 토큰. Apple은 필수에 가깝게 사용.
  - `include_refresh_token` (선택): `true` 시 리프레시 토큰을 Set-Cookie 등으로 내려주는 방식일 수 있음.
- **Response (200)**:
  - Body: 기존 로그인과 동일한 사용자 정보 + JWT. 예: `access_token`, `token_type`, `expires_in`, `user_id`, `email`, `name`, `user_type`, `user_type_name`, `is_admin`, `is_coach`, `role`, `provider` 등.
  - Set-Cookie: 리프레시 토큰(백엔드 구현에 따라).
- **에러**:
  - 404: 엔드포인트 없음 → "소셜 로그인 API를 찾을 수 없습니다."
  - 4xx/5xx: 네트워크 로그 확인 후 "서버 연결에 실패했습니다." 또는 백엔드 에러 메시지 전달.

### 7.2 소셜 계정 연동용 API (선택 구현)

- **GET** `/api/v1/auth/social/linked`: 로그인된 사용자의 연동 소셜 계정 목록.
- **DELETE** `/api/v1/auth/social/link/{provider}`: 해당 provider 연동 해제.
- **POST** `/api/v1/auth/social/link/token`: SDK에서 받은 토큰으로 추가 연동 (구현 시 참고).

---

## 8. 소셜 계정 연동 (선택)

### 8.1 기존 로그인 + 카카오 SDK 연동 (이 프로젝트)

- **진입**: 마이페이지 → **소셜 계정 연동** 영역 → 카카오 **연동** 버튼.
- **흐름**: (1) 이미 이메일/비밀번호 등으로 로그인된 상태 (2) 카카오 **연동** 탭 → Kakao SDK 로그인(카카오톡/카카오계정) (3) 앱이 카카오 access_token 획득 (4) 백엔드에 **현재 JWT**(Authorization) + **access_token** 전달하여 연동.
- **AuthService**: `linkSocialAccountWithSdk('kakao')` → `_getKakaoAccessTokenForLink()` 로 토큰만 획득(세션 변경 없음) → `POST /api/v1/auth/social/link/token` 호출.
- **백엔드 필요**: `POST /api/v1/auth/social/link/token`  
  - **Headers**: `Authorization: Bearer {현재 사용자 JWT}`  
  - **Body (JSON)**: `{ "provider": "kakao", "access_token": "카카오 액세스 토큰" }`  
  - **Response 200**: 연동된 사용자 정보(기존 로그인 응답과 동일 형식).  
  - 404 시 클라이언트는 "계정 연동 API를 찾을 수 없습니다" 메시지 표시.

### 8.2 별도 연동 전용 화면 (일부 워크트리)

- **라우트**: `AppRoutes.socialLink` → `/settings/social-link`
- **화면**: `lib/screens/settings/social_link_screen.dart` (일부 워크트리에서만 구현됨).
- **기능**: 연동된 소셜 목록 조회(GET /api/v1/auth/social/linked), 연동/해제, **provider별 로딩 상태**(`_processingProviders`)로 한 버튼만 로딩 표시.

---

## 9. 빌드 및 실행

```bash
# 의존성 설치
flutter pub get

# Android 에뮬레이터 (API_BASE_URL 지정)
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:9500

# AndroidManifest 수정 후 반드시 클린 빌드
flutter clean
flutter pub get
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:9500
```

- **10.0.2.2**: Android 에뮬레이터에서 호스트 PC의 localhost(127.0.0.1)를 가리킴. 백엔드가 PC에서 9500 포트로 떠 있어야 함.

---

## 10. 트러블슈팅 상세

| 현상 | 원인 | 해결 |
|------|------|------|
| 소셜 로그인 버튼이 안 보임 | `enableSocialLogin` 이 false. | `lib/utils/feature_flags.dart` 에서 `defaultValue: true` 인지 확인. 또는 `WPI_ENABLE_SOCIAL_LOGIN=false` 로 실행 중이면 제거. |
| "소셜 로그인이 아직 준비되지 않았습니다" | `loginWithSocial` 이 플레이스홀더로만 구현됨. | `AuthService` 에 `_loginWithKakaoSdk`, `_loginWithGoogleSdk`, `_loginWithAppleSdk`, `_exchangeSocialToken`, `_handleSocialLoginResponse` 구현이 있는지 확인. |
| 카카오 "계속하기" 후 앱으로 안 돌아옴 | ① intent-filter 없음 ② Manifest 미반영 ③ 카카오 콘솔 미설정 | ① MainActivity에 카카오 scheme/host intent-filter 추가. ② `flutter clean` 후 재빌드. ③ Redirect URI `kakaoa531a4604dfddd5837c464cc44053e5d://oauth` 및 Android 키 해시 등록. |
| 백엔드 404 | `/api/v1/auth/social/token` 미구현 또는 경로 상이 | 백엔드 라우트 및 URL 확인. 클라이언트 `_uri()` 가 올바른 BASE_URL 사용하는지 확인. |
| 연동 버튼 여러 개가 동시에 로딩 | 한 플래그(_isProcessing)로 전체 제어 | provider별 `_processingProviders[provider]` 로 로딩 상태 분리. |

---

## 11. 발생한 에러 및 수정 내역

개발 과정에서 발생한 에러와, 각각 **어떻게 수정했는지** 정리한 내용입니다.

### 11.1 로그인 화면에서 소셜 로그인 버튼이 안 보임

- **증상**: 로그인 화면에 카카오/Apple/Google 버튼이 전혀 표시되지 않음.
- **원인**: `lib/utils/feature_flags.dart` 에서 `enableSocialLogin` 의 `defaultValue` 가 `false` 로 되어 있어, 소셜 버튼 블록이 `if (socialEnabled)` 조건으로 렌더링되지 않음.
- **수정**: `defaultValue` 를 `true` 로 변경.
  ```dart
  static const bool enableSocialLogin = bool.fromEnvironment(
    'WPI_ENABLE_SOCIAL_LOGIN',
    defaultValue: true,  // false → true
  );
  ```

### 11.2 "소셜 로그인이 아직 준비되지 않았습니다" 메시지

- **증상**: 소셜 로그인 버튼을 눌렀을 때 위 메시지만 뜨고 진행되지 않음.
- **원인**: `AuthService.loginWithSocial(provider)` 가 플레이스홀더로만 구현되어 있어, 항상 `AuthResult.failure('소셜 로그인이 아직 준비되지 않았습니다.')` 를 반환함.
- **수정**:
  1. `pubspec.yaml` 에 소셜 SDK 의존성 추가 (`kakao_flutter_sdk_user`, `google_sign_in`, `sign_in_with_apple`, `app_links`).
  2. `auth_service.dart` 에 실제 구현 추가:
     - `_loginWithKakaoSdk()`: 카카오톡/카카오계정 로그인 후 access_token 획득.
     - `_loginWithGoogleSdk()`: Google Sign-In 후 access_token / id_token 획득.
     - `_loginWithAppleSdk()`: Sign in with Apple 후 id_token 획득 (iOS/macOS만).
     - `_exchangeSocialToken()`: 백엔드 `POST /api/v1/auth/social/token` 호출.
     - `_handleSocialLoginResponse()`: 응답으로 UserInfo·AuthTokens 저장.
  3. `main.dart` 에서 Kakao SDK 초기화 (`KakaoSdk.init(nativeAppKey: '...')`).

### 11.3 카카오 "계속하기" 후 앱으로 돌아오지 않음

- **증상**: 카카오 로그인/동의 화면에서 "계속하기"를 눌러도 앱으로 복귀하지 않고, 브라우저/카카오 화면에 머무름.
- **원인**: 카카오가 로그인 완료 후 `kakaoa531a4604dfddd5837c464cc44053e5d://oauth?code=xxx` 로 리다이렉트하는데, Android 쪽에서 이 URI를 받을 **intent-filter**가 없어서 우리 앱이 열리지 않음.
- **수정**:
  1. `android/app/src/main/AndroidManifest.xml` 의 **MainActivity** 안에 아래 intent-filter 추가.
     ```xml
     <intent-filter>
         <action android:name="android.intent.action.VIEW"/>
         <category android:name="android.intent.category.DEFAULT"/>
         <category android:name="android.intent.category.BROWSABLE"/>
         <data android:scheme="kakaoa531a4604dfddd5837c464cc44053e5d" android:host="oauth"/>
     </intent-filter>
     ```
  2. Manifest 변경은 핫 리로드로 반영되지 않으므로 **`flutter clean` 후 재빌드** 실행.
  3. 카카오 개발자 콘솔에 **Redirect URI** `kakaoa531a4604dfddd5837c464cc44053e5d://oauth` 및 **Android 키 해시** 등록 확인.

### 11.4 소셜 계정 연동 화면이 빈 페이지로 뜸

- **증상**: 마이페이지에서 "소셜 계정 연동"을 눌렀을 때 빈 화면만 표시됨.
- **원인**: 해당 워크트리/프로젝트에 `SocialLinkScreen` 위젯과 라우트가 없거나, 라우터에 등록되지 않음.
- **수정**:
  1. `lib/screens/settings/social_link_screen.dart` 생성 (연동 목록 조회, 연동/해제 UI).
  2. `lib/router/app_routes.dart` 에 `static const socialLink = '/settings/social-link';` 추가.
  3. `lib/router/app_router.dart` 에 `case AppRoutes.socialLink: return _page(..., SocialLinkScreen());` 및 import 추가.
  4. `lib/screens/profile/my_page_screen.dart` 설정 영역에 "소셜 계정 연동" 메뉴 추가 후 `pushNamed(AppRoutes.socialLink)` 연결.

### 11.5 소셜 계정 연동 화면에서 ListTile 레이아웃 에러

- **증상**: 런타임 에러  
  `Trailing widget consumes the entire tile width (including ListTile.contentPadding).`
- **원인**: `ListTile` 의 `trailing` 에 넣은 버튼(연동/해제)이 너무 넓어서, ListTile 규격상 trailing 영역이 타일 전체 너비를 넘어감.
- **수정**:
  1. `trailing` 위젯을 **고정 너비** 로 감쌈: `SizedBox(width: 70, child: ...)`.
  2. 버튼 스타일 조정: `padding: EdgeInsets.zero` 또는 `padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)`, `minimumSize: Size.zero`, `tapTargetSize: MaterialTapTargetSize.shrinkWrap` 로 trailing 영역 안에 들어가도록 함.

### 11.6 연동 버튼을 하나만 눌렀는데 모든 소셜 버튼이 로딩 상태로 보임

- **증상**: 카카오 "연동"만 눌렀는데 카카오/Google/Apple 연동 버튼이 모두 로딩 스피너로 바뀜.
- **원인**: 소셜 계정 연동 화면에서 로딩 상태를 **하나의 `_isProcessing`** 만으로 관리해, 어떤 provider가 처리 중인지 구분하지 않음.
- **수정**: provider별 로딩 상태 맵 도입.
  ```dart
  final Map<String, bool> _processingProviders = {
    'kakao': false,
    'google': false,
    'apple': false,
  };
  ```
  - 연동/해제 시작 시: `_processingProviders[provider] = true`.
  - 종료 시: `_processingProviders[provider] = false`.
  - 각 타일의 trailing 에서는 **해당 provider만** `isProcessing = _processingProviders[provider]` 로 판단해, 그 줄만 로딩 스피너 표시.

### 11.7 일반 로그인 422 Unprocessable Entity (참고)

- **증상**: 이메일/비밀번호로 로그인 시 백엔드에서 422 반환.
- **원인**: 백엔드가 `application/x-www-form-urlencoded` + 필드명 `username`, `password` 를 기대하는데, 클라이언트가 JSON 등 다른 형식으로 보내거나 필드명이 `email` 인 경우.
- **수정**: `AuthService.loginWithEmail()` 에서 `Content-Type: formUrlEncoded`, Body 필드 `username`(이메일 값), `password` 로 전송하도록 수정. (현재 프로젝트에서 이미 반영된 사항임.)

### 11.8 AuthTokens 생성 시 파라미터명 불일치 (SDK 구현 시)

- **증상**: `_handleSocialLoginResponse` 에서 `AuthTokens(refreshToken: ..., expiresAt: ...)` 처럼 호출 시 컴파일 에러 — `refreshToken` / `expiresAt` 이 정의되지 않음.
- **원인**: 실제 `AuthTokens` 클래스는 `refreshTokenCookie`, `accessTokenExpiresAt` 파라미터를 사용함.
- **수정**: `AuthTokens` 생성 시 `refreshTokenCookie`, `accessTokenExpiresAt` 로 맞춰서 호출.

### 11.9 소셜 연동 화면에서 AppColors.surface 미정의 (선택 구현 시)

- **증상**: `AppColors.surface` 사용 시 `undefined getter 'surface'` 에러.
- **원인**: `AppColors` 에 `surface` 상수가 없음.
- **수정**: `AppColors.surface` → `AppColors.cardBackground` (또는 프로젝트에 정의된 다른 배경용 상수)로 변경.

---

## 12. 수정/추가된 파일 목록

| 파일 | 변경 요약 |
|------|------------|
| `pubspec.yaml` | 소셜 SDK 의존성 4종 추가. |
| `lib/main.dart` | Kakao SDK 초기화, Key Hash 디버그 출력. |
| `lib/utils/feature_flags.dart` | `enableSocialLogin` 기본값 `true`. |
| `lib/services/auth_service.dart` | `loginWithSocial`, `_loginWithKakaoSdk`, `_loginWithGoogleSdk`, `_loginWithAppleSdk`, `_exchangeSocialToken`, `_handleSocialLoginResponse` 구현. |
| `lib/screens/auth/login_screen.dart` | `FeatureFlags.enableSocialLogin` 기준 소셜 버튼 표시, `_handleSocialLogin` 연동. |
| `android/app/src/main/AndroidManifest.xml` | MainActivity에 카카오 OAuth 리다이렉트용 intent-filter 추가. |

소셜 계정 연동 화면을 쓰는 경우 추가:

- `lib/router/app_routes.dart` — `socialLink` 상수.
- `lib/router/app_router.dart` — `SocialLinkScreen` 라우트.
- `lib/screens/settings/social_link_screen.dart` — 연동 화면 및 provider별 로딩.
- `lib/screens/profile/my_page_screen.dart` — "소셜 계정 연동" 메뉴.
