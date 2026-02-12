# Flutter 앱 빌드

Flutter 앱을 빌드합니다.

## 사용법
```
/build [platform] [mode]
```

## 인자
$ARGUMENTS

- `platform`: 빌드 대상 플랫폼
  - `apk` - Android APK (기본값)
  - `appbundle` - Android App Bundle (AAB)
  - `ios` - iOS 빌드
  - `ipa` - iOS IPA 파일
  - `web` - 웹 빌드

- `mode`: 빌드 모드
  - `release` - 릴리즈 모드 (기본값)
  - `debug` - 디버그 모드
  - `profile` - 프로파일 모드

## 빌드 명령

플랫폼에 따라 적절한 명령어를 실행하세요:

1. **APK**: `flutter build apk --release`
2. **App Bundle**: `flutter build appbundle --release`
3. **iOS**: `flutter build ios --release`
4. **IPA**: `flutter build ipa --release`
5. **Web**: `flutter build web --release`

빌드 전 `flutter pub get`으로 의존성을 확인하고, 빌드 결과물 위치를 사용자에게 안내하세요:
- APK: `build/app/outputs/flutter-apk/`
- App Bundle: `build/app/outputs/bundle/release/`
- iOS: `build/ios/iphoneos/`
- Web: `build/web/`
