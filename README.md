# WPI 마음읽기 (Flutter App)

심리 검사 기반 마음 구조 분석 애플리케이션입니다.

## 📋 목차

1. [프로젝트 개요](#프로젝트-개요)
2. [개발 환경 요구사항](#개발-환경-요구사항)
3. [설치 가이드](#설치-가이드)
4. [실행 방법](#실행-방법)
5. [프로젝트 구조](#프로젝트-구조)
6. [주요 기능](#주요-기능)
7. [문제 해결](#문제-해결)

## 📚 OS별 상세 가이드

| 운영체제 | 가이드 문서 |
|---------|------------|
| **Windows** | 👉 [INSTALL_WINDOWS.md](./INSTALL_WINDOWS.md) |
| **macOS** | 이 문서의 [설치 가이드](#설치-가이드) 참조 |
| **빠른 시작** | 👉 [QUICK_START.md](./QUICK_START.md) |

---

## 프로젝트 개요

WPI(Whole Person Inventory) 검사를 통해 사용자의 마음 구조를 분석하고, 
"빨간선(자기 믿음)"과 "파란선(내면화된 기준)" 간의 관계를 시각화하여 보여주는 앱입니다.

### 주요 화면
- 스플래시 / 웰컴 화면
- 온보딩 (3페이지)
- 로그인 / 회원가입 (소셜 로그인 지원)
- 대시보드 (검사 이력 관리)
- WPI 검사 (5문항 샘플)
- 결과 분석 화면

---

## 개발 환경 요구사항

| 항목 | 최소 버전 | 권장 버전 |
|------|----------|----------|
| Flutter SDK | 3.16.0 | 3.24.0+ |
| Dart SDK | 3.2.0 | 3.5.0+ |
| Xcode (macOS) | 14.0 | 15.0+ |
| Android Studio | Flamingo | Hedgehog+ |
| VS Code / Cursor | - | 최신 버전 |

### 운영체제별 추가 요구사항

#### macOS
- Xcode Command Line Tools
- CocoaPods (iOS 빌드 시)

#### Windows
- Visual Studio 2022 (Windows 데스크톱 빌드 시)
- Android SDK

#### Linux
- clang, cmake, ninja-build, pkg-config, libgtk-3-dev

---

## 설치 가이드

### 1단계: Flutter SDK 설치

#### macOS (Apple Silicon - M1/M2/M3)

```bash
# Flutter SDK 다운로드
cd ~
curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_arm64_3.24.5-stable.zip

# 압축 해제
unzip flutter_macos_arm64_3.24.5-stable.zip

# PATH 설정 (zsh 기준)
echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# 설치 확인
flutter --version
```

#### macOS (Intel)

```bash
# Flutter SDK 다운로드
cd ~
curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_3.24.5-stable.zip

# 압축 해제
unzip flutter_macos_3.24.5-stable.zip

# PATH 설정
echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

#### Windows

1. [Flutter 공식 사이트](https://docs.flutter.dev/get-started/install/windows)에서 SDK 다운로드
2. `C:\flutter` 폴더에 압축 해제
3. 시스템 환경 변수 PATH에 `C:\flutter\bin` 추가

#### Linux

```bash
# Snap을 통한 설치 (권장)
sudo snap install flutter --classic

# 또는 수동 설치
cd ~
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.5-stable.tar.xz
tar xf flutter_linux_3.24.5-stable.tar.xz
echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### 2단계: Flutter 환경 점검

```bash
# Flutter 환경 진단
flutter doctor

# 모든 항목이 ✓ 표시되어야 합니다
# 필요한 경우 안내에 따라 추가 설치 진행
```

### 3단계: 프로젝트 클론

```bash
# Git 저장소 클론
git clone <repository-url>
cd interpreter_front

# 또는 프로젝트 폴더로 이동
cd /path/to/interpreter_front_flutter
```

### 4단계: 의존성 설치

```bash
# 패키지 의존성 설치
flutter pub get
```

---

## 실행 방법

### 웹 브라우저에서 실행 (권장 - 가장 간단)

```bash
# 웹 서버로 실행
flutter run -d web-server --web-port=8080 --web-hostname=localhost

# 브라우저에서 접속
# http://localhost:8080
```

### Chrome 브라우저에서 실행 (디버깅 지원)

```bash
# Chrome이 설치되어 있어야 함
flutter run -d chrome
```

### macOS 앱으로 실행

```bash
# Xcode가 설치되어 있어야 함
flutter run -d macos
```

### iOS 시뮬레이터에서 실행

```bash
# Xcode 및 시뮬레이터 필요
open -a Simulator
flutter run -d ios
```

### Android 에뮬레이터에서 실행

```bash
# Android Studio 및 에뮬레이터 필요
flutter run -d android
```

### 실행 가능한 디바이스 확인

```bash
flutter devices
```

---

## 프로젝트 구조

```
interpreter_front/
├── lib/
│   ├── main.dart                    # 앱 진입점
│   ├── models/                      # 데이터 모델
│   │   ├── test_history.dart        # 검사 이력 모델
│   │   └── wpi_result.dart          # WPI 결과 모델
│   ├── screens/                     # 화면 위젯
│   │   ├── auth/                    # 인증 관련
│   │   │   ├── login_screen.dart
│   │   │   └── signup_screen.dart
│   │   ├── onboarding/              # 온보딩
│   │   │   ├── onboarding_screen.dart
│   │   │   ├── onboarding_page1.dart
│   │   │   ├── onboarding_page2.dart
│   │   │   └── onboarding_page3.dart
│   │   ├── test/                    # 검사 화면
│   │   │   ├── test_intro_screen.dart
│   │   │   └── test_screen.dart
│   │   ├── result/                  # 결과 화면
│   │   │   ├── result_summary_screen.dart
│   │   │   ├── existence_detail_screen.dart
│   │   │   └── test_history_detail_screen.dart
│   │   ├── profile/                 # 프로필
│   │   │   └── my_page_screen.dart
│   │   ├── settings/                # 설정
│   │   │   └── notification_settings_screen.dart
│   │   ├── splash_screen.dart
│   │   ├── welcome_screen.dart
│   │   ├── entry_screen.dart
│   │   └── dashboard_screen.dart
│   ├── services/                    # 비즈니스 로직
│   │   ├── auth_service.dart        # 인증 서비스
│   │   └── notification_service.dart # 알림 서비스
│   ├── utils/                       # 유틸리티
│   │   ├── app_colors.dart          # 색상 상수
│   │   ├── app_text_styles.dart     # 텍스트 스타일
│   │   ├── app_theme.dart           # 테마 설정
│   │   ├── constants.dart           # 전역 상수
│   │   ├── helpers.dart             # 헬퍼 함수
│   │   └── utils.dart               # 배럴 파일
│   └── widgets/                     # 공통 위젯
│       └── social_login_buttons.dart
├── pubspec.yaml                     # 의존성 정의
├── analysis_options.yaml            # 린트 설정
└── README.md                        # 이 파일
```

---

## 주요 기능

### 🔐 인증
- 이메일/비밀번호 로그인 (임시)
- 소셜 로그인 (카카오, 네이버, 구글, 페이스북) - UI만 구현
- 게스트 로그인 (테스트용)

### 📊 WPI 검사
- 5문항 샘플 검사
- 5점 리커트 척도 응답
- 실시간 진행률 표시

### 📈 결과 분석
- 존재 유형 분석 (조화형, 도전형, 안정형 등)
- 빨간선/파란선 시각화
- Gap 분석
- 해석 가이드 및 추천 액션

### 🔔 알림
- 검사 완료 알림
- 30일 후 검사 권유 알림

---

## 문제 해결

### Flutter 명령어를 찾을 수 없음

```bash
# PATH 설정 확인
echo $PATH | grep flutter

# PATH에 flutter가 없으면 다시 설정
export PATH="$HOME/flutter/bin:$PATH"
```

### flutter doctor 에러

```bash
# Android SDK 라이선스 동의
flutter doctor --android-licenses

# Xcode 설정 (macOS)
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

### 웹 빌드 에러

```bash
# Flutter 웹 지원 활성화
flutter config --enable-web

# 캐시 정리 후 재시도
flutter clean
flutter pub get
flutter run -d chrome
```

### 포트 8080 사용 중

```bash
# 사용 중인 프로세스 종료
lsof -ti:8080 | xargs kill -9

# 다른 포트로 실행
flutter run -d web-server --web-port=3000 --web-hostname=localhost
```

### 패키지 의존성 에러

```bash
# pubspec.lock 삭제 후 재설치
rm pubspec.lock
flutter pub get
```

### Hot Reload가 작동하지 않음

- 웹 서버 모드에서는 Hot Reload 대신 `r` 키를 눌러 Hot Restart 사용
- Chrome 디버그 모드(`flutter run -d chrome`)에서 Hot Reload 지원

---

## 개발 팁

### 코드 분석

```bash
# 린트 검사
flutter analyze

# 포맷팅
dart format lib/
```

### 빌드

```bash
# 웹 빌드
flutter build web

# Android APK 빌드
flutter build apk

# iOS 빌드 (macOS 필요)
flutter build ios
```

### 테스트

```bash
# 단위 테스트 실행
flutter test
```

---

## 라이선스

이 프로젝트는 내부 개발용입니다.

---

## 문의

프로젝트 관련 문의사항은 팀 리더에게 연락해주세요.
