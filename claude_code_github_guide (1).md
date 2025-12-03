# Claude Code & GitHub 작업 가이드

## 🚀 방법 1: Claude Code에서 직접 작업 (추천)

### 1.1 프로젝트 클론 및 설정
```bash
# Claude Code 터미널에서 실행
cd ~/projects
git clone https://github.com/aiguma/interpreter_front.git
cd interpreter_front

# Flutter 프로젝트 초기화
flutter pub get
flutter doctor
```

### 1.2 Claude Code에서 작업 명령
```bash
# Claude Code 실행 (터미널에서)
claude-code

# 프롬프트 예시:
"Flutter WPI 앱 프로젝트를 시작합니다. 
/mnt/user-data/outputs/wpi_flutter_screen_design.md 파일의 
화면 구성도를 참고하여 lib/screens 폴더에 화면들을 구현해주세요."
```

### 1.3 파일 참조 방법
Claude Code에서 현재 제가 생성한 문서들을 참조하려면:

```bash
# 옵션 1: 파일 내용을 복사
cat /mnt/user-data/outputs/wpi_flutter_screen_design.md > ~/projects/interpreter_front/docs/screen_design.md
cat /mnt/user-data/outputs/flutter_cross_platform_setup.md > ~/projects/interpreter_front/docs/platform_setup.md

# 옵션 2: Claude Code에 직접 전달
claude-code --file /mnt/user-data/outputs/wpi_flutter_screen_design.md
```

## 🔧 방법 2: 현재 환경에서 직접 작업

### 2.1 GitHub 리포지토리 클론
```bash
# 현재 Claude 환경에서 실행 가능
git clone https://github.com/aiguma/interpreter_front.git
cd interpreter_front
```

### 2.2 Flutter 프로젝트 구조 생성
```bash
# Flutter 프로젝트 초기 구조 생성
flutter create . --org com.wpi --project-name wpi_app
```

### 2.3 기본 파일 구조
```
interpreter_front/
├── lib/
│   ├── main.dart
│   ├── screens/
│   │   ├── splash_screen.dart
│   │   ├── onboarding/
│   │   │   ├── welcome_screen.dart
│   │   │   └── entry_screen.dart
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   └── signup_screen.dart
│   │   ├── test/
│   │   │   ├── test_intro_screen.dart
│   │   │   └── test_screen.dart
│   │   ├── result/
│   │   │   ├── result_summary_screen.dart
│   │   │   └── existence_detail_screen.dart
│   │   └── profile/
│   │       └── my_page_screen.dart
│   ├── widgets/
│   │   ├── adaptive_widgets.dart
│   │   └── common_widgets.dart
│   ├── models/
│   │   ├── wpi_result.dart
│   │   └── user.dart
│   ├── services/
│   │   ├── api_service.dart
│   │   ├── wpi_service.dart
│   │   └── auth_service.dart
│   └── utils/
│       ├── constants.dart
│       └── theme.dart
├── android/
├── ios/
├── assets/
│   ├── images/
│   ├── icons/
│   └── fonts/
├── test/
└── pubspec.yaml
```

## 📝 작업 시작 템플릿

### pubspec.yaml 설정
```yaml
name: wpi_app
description: WPI 심리 검사 애플리케이션
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  
  # UI
  cupertino_icons: ^1.0.6
  flutter_native_splash: ^2.3.8
  
  # 상태 관리
  provider: ^6.1.1
  
  # 네트워킹
  dio: ^5.4.0
  retrofit: ^4.0.3
  json_annotation: ^4.8.1
  
  # 로컬 저장소
  shared_preferences: ^2.2.2
  
  # 유틸리티
  intl: ^0.18.1
  flutter_svg: ^2.0.9

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
  build_runner: ^2.4.7
  json_serializable: ^6.7.1
  retrofit_generator: ^8.0.6

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/icons/
```

### lib/main.dart 시작 코드
```dart
import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(WPIApp());
}

class WPIApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WPI 마음읽기',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF0F4C81),
        ),
        useMaterial3: true,
        fontFamily: 'Pretendard',
      ),
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
```

## 🎯 Claude Code 프롬프트 예시

### 화면 구현 요청
```
"lib/screens/splash_screen.dart 파일을 생성해주세요.
다음 요구사항을 포함해야 합니다:
1. WPI 로고 애니메이션
2. 2-3초 후 자동으로 WelcomeScreen으로 전환
3. Color(0xFF1A1A2E) 배경색 사용"
```

### API 서비스 구현 요청
```
"lib/services/wpi_service.dart를 생성해주세요.
WPI 검사 API와 통신하는 서비스 클래스를 구현하고,
다음 메소드들을 포함해주세요:
- submitAnswers(Map<String, int> answers)
- getResult(String testId)
- getTestHistory(String userId)"
```

### 모델 클래스 생성
```
"lib/models/wpi_result.dart를 생성해주세요.
JSON serializable을 사용하여 WPI 검사 결과 모델을 만들고,
다음 필드들을 포함해주세요:
- existenceType (5가지 유형)
- redLineValue, blueLineValue
- gapAnalysis
- emotionalSignals (List<String>)
- bodySignals (List<String>)"
```

## 🔄 GitHub 푸시 방법

### 현재 환경에서 작업 후 푸시
```bash
# 작업 완료 후
cd interpreter_front
git add .
git commit -m "feat: WPI 앱 초기 Flutter 프로젝트 구성"

# GitHub 인증 설정
git config --global user.name "aiguma"
git config --global user.email "your-email@example.com"

# 푸시 (Personal Access Token 필요)
git push origin main
```

### Claude Code에서 작업 후 푸시
```bash
# Claude Code는 자동으로 git 명령어를 처리
# 프롬프트에서 직접 요청 가능:
"변경사항을 커밋하고 GitHub에 푸시해주세요. 
커밋 메시지는 'feat: WPI 앱 화면 구현'으로 작성해주세요."
```

## 📌 중요 참고사항

### 1. 문서 활용 방법
생성된 문서들을 프로젝트에 포함시키기:
```bash
# docs 폴더 생성 및 문서 복사
mkdir -p interpreter_front/docs
cp /mnt/user-data/outputs/*.md interpreter_front/docs/
```

### 2. Claude Code 장점
- 자동으로 코드 생성 및 수정
- 여러 파일 동시 작업 가능
- Git 작업 자동화
- 테스트 코드 자동 생성

### 3. 현재 환경 작업 장점
- 직접 파일 확인 가능
- 세밀한 제어 가능
- 즉시 결과 확인

## 🚨 주의사항

1. **GitHub Personal Access Token 필요**
   - Settings → Developer settings → Personal access tokens
   - repo 권한 필수

2. **Flutter 환경 설정**
   ```bash
   # Flutter SDK 설치 확인
   flutter doctor
   
   # 필요시 설치
   curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.16.0-stable.tar.xz
   tar xf flutter_linux_3.16.0-stable.tar.xz
   export PATH="$PATH:`pwd`/flutter/bin"
   ```

3. **의존성 충돌 해결**
   ```bash
   flutter clean
   flutter pub get
   flutter pub upgrade
   ```

## 💡 추천 워크플로우

1. **현재 Claude에서**: 
   - 문서 생성 ✅ (완료)
   - 프로젝트 구조 설계 ✅ (완료)
   - 초기 파일 생성

2. **Claude Code에서**:
   - 상세 구현
   - 반복적인 코드 생성
   - 테스트 코드 작성

3. **로컬 개발 환경에서**:
   - 실제 빌드 및 테스트
   - 디버깅
   - 최종 배포

이렇게 각 도구의 장점을 활용하면 효율적인 개발이 가능합니다!
