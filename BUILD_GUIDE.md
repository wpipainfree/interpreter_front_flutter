# WPI App 빌드 가이드

## 개발 환경 요구사항

### 공통
- Flutter SDK: 3.38.3 이상
- Dart SDK: 3.10.1 이상

### Android
- Android Studio 또는 Android SDK
- Android SDK version 36.1.0
- Java 17

### iOS (Mac 필요)
- Xcode 26.2 이상
- CocoaPods 1.16.2 이상
- macOS

## 빌드 방법

### 1. 프로젝트 클론 및 설정
```bash
git clone [repository-url]
cd interpreter_front_flutter
flutter pub get
```

### 2. Android 빌드

#### 디버그 빌드 (테스트용)
```bash
flutter build apk --debug
```
생성 위치: `build/app/outputs/flutter-apk/app-debug.apk`

#### 릴리스 빌드
```bash
flutter build apk --release
```
생성 위치: `build/app/outputs/flutter-apk/app-release.apk`

### 3. iOS 빌드 (Mac에서만 가능)

#### CocoaPods 의존성 설치
```bash
cd ios
pod install
cd ..
```

#### 시뮬레이터용 빌드
```bash
flutter build ios --simulator
```

#### 실제 기기용 빌드
```bash
flutter build ios --release
```
※ 실제 기기 테스트는 Apple Developer 계정 필요 (무료 가능)

## 프로젝트 정보

- **앱 이름**: Wpi App
- **Package Name (Android)**: com.wpipainfree.wpiapp
- **Bundle ID (iOS)**: 프로젝트 설정에서 확인
- **최소 지원 버전**:
  - Android: Flutter 기본값 (API 21)
  - iOS: Flutter 기본값 (iOS 12.0)

## 주요 기능
- WPI 심리 검사 애플리케이션
- 결제 시스템 연동 (INICIS)
- WebView 기반 결제 처리
- 딥링크 지원 (wpiapp://)

## 문제 해결

### Android 라이선스 문제
```bash
flutter doctor --android-licenses
```

### iOS Pod 설치 실패
```bash
cd ios
pod repo update
pod install --repo-update
```

### 빌드 캐시 문제
```bash
flutter clean
flutter pub get
```

## 배포 준비사항

### Android
- Keystore 파일 생성 및 서명 설정
- Google Play Console 계정

### iOS
- Apple Developer 계정
- 프로비저닝 프로파일
- App Store Connect 설정

## 연락처
문제가 있으시면 이슈를 등록해주세요.