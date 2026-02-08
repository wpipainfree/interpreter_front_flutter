# iOS 설정 및 실행

WPI 앱의 iOS 플랫폼 설정을 확인하고 실행합니다.

## 사용법
```
/ios [action]
```

## 인자
$ARGUMENTS

- `action` (선택): run, build, clean, config

## 실행 명령

### 앱 실행
```bash
flutter run -d ios
# 시뮬레이터 지정
flutter run -d "iPhone 15 Pro"
```

### 빌드
```bash
# Debug
flutter build ios --debug

# Release
flutter build ios --release

# IPA (배포용)
flutter build ipa --release
```

### Xcode에서 실행
```bash
open ios/Runner.xcworkspace
```

## 주요 설정 파일

### Info.plist (`ios/Runner/Info.plist`)
- Bundle ID: `com.wpi.app`
- URL Schemes (소셜 로그인, 딥링크)
- 권한 설명 (카메라, 알림 등)

### Podfile (`ios/Podfile`)
```ruby
platform :ios, '13.0'
```

## 소셜 로그인 설정

### 카카오
```xml
<!-- Info.plist -->
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>kakao{NATIVE_APP_KEY}</string>
    </array>
  </dict>
</array>

<key>LSApplicationQueriesSchemes</key>
<array>
  <string>kakaokompassauth</string>
  <string>kakaolink</string>
</array>
```

### Google
- `ios/Runner/GoogleService-Info.plist` 필요
```xml
<key>CFBundleURLSchemes</key>
<array>
  <string>com.googleusercontent.apps.{CLIENT_ID}</string>
</array>
```

### Apple Sign In
- `ios/Runner/Runner.entitlements`에 Sign In with Apple capability 추가
- Apple Developer Console에서 App ID 설정

## 딥링크 설정 (결제 콜백)
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>wpiapp</string>
    </array>
  </dict>
</array>
```

## 문제 해결

### Pod 설치 오류
```bash
cd ios && pod deintegrate && pod install && cd ..
```

### 빌드 실패
```bash
flutter clean
cd ios && rm -rf Pods Podfile.lock && pod install && cd ..
flutter pub get
```

### 서명 오류
Xcode에서 Signing & Capabilities 확인:
- Team 선택
- Bundle Identifier 확인
- Provisioning Profile 설정

### M1/M2 Mac 이슈
```bash
cd ios && arch -x86_64 pod install && cd ..
```

## Xcode 설정 확인

1. **Runner.xcworkspace** 열기 (xcodeproj 아님)
2. **Signing & Capabilities** 탭:
   - Team 선택
   - Sign In with Apple 추가 (Apple 로그인용)
3. **Info** 탭:
   - URL Types 확인
