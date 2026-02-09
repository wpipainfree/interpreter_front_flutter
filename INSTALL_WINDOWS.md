# 🪟 Windows 설치 가이드

Windows 환경에서 WPI 마음읽기 프로젝트를 설치하고 실행하는 방법입니다.

---

## 📋 목차

1. [시스템 요구사항](#시스템-요구사항)
2. [Flutter SDK 설치](#flutter-sdk-설치)
3. [환경 변수 설정](#환경-변수-설정)
4. [Git 설치](#git-설치)
5. [프로젝트 실행](#프로젝트-실행)
6. [문제 해결](#문제-해결)

---

## 시스템 요구사항

| 항목 | 요구사항 |
|------|----------|
| 운영체제 | Windows 10 이상 (64-bit) |
| 디스크 공간 | 최소 2.5GB (IDE 제외) |
| 도구 | Windows PowerShell 5.0 이상 |
| Git | Git for Windows 2.27 이상 |

---

## Flutter SDK 설치

### 방법 1: 공식 사이트에서 다운로드 (권장)

#### 1단계: SDK 다운로드

1. 아래 링크에서 Flutter SDK를 다운로드합니다:
   
   **👉 [Flutter SDK 다운로드](https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.5-stable.zip)**

   또는 공식 사이트: https://docs.flutter.dev/get-started/install/windows

#### 2단계: 압축 해제

1. 다운로드한 `flutter_windows_3.24.5-stable.zip` 파일을 찾습니다
2. **C:\flutter** 폴더에 압축을 해제합니다

   > ⚠️ **주의**: `C:\Program Files\` 같은 권한이 필요한 폴더는 피하세요!

   압축 해제 후 폴더 구조:
   ```
   C:\flutter\
   ├── bin\
   ├── packages\
   ├── dev\
   └── ...
   ```

### 방법 2: PowerShell로 설치

PowerShell을 **관리자 권한**으로 실행하고 아래 명령어를 입력합니다:

```powershell
# 다운로드 폴더로 이동
cd $env:USERPROFILE\Downloads

# Flutter SDK 다운로드
Invoke-WebRequest -Uri "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.5-stable.zip" -OutFile "flutter.zip"

# C:\flutter에 압축 해제
Expand-Archive -Path "flutter.zip" -DestinationPath "C:\"

# 압축 파일 삭제 (선택)
Remove-Item "flutter.zip"
```

---

## 환경 변수 설정

Flutter 명령어를 어디서든 사용하려면 PATH 환경 변수에 추가해야 합니다.

### GUI로 설정하기

1. **Windows 키 + R** 을 눌러 실행 창을 엽니다
2. `sysdm.cpl` 입력 후 Enter
3. **고급** 탭 클릭
4. **환경 변수** 버튼 클릭
5. **시스템 변수** 섹션에서 **Path** 선택 후 **편집** 클릭
6. **새로 만들기** 클릭
7. `C:\flutter\bin` 입력
8. **확인** 버튼을 눌러 모든 창 닫기

### PowerShell로 설정하기 (관리자 권한)

```powershell
# 현재 PATH에 Flutter 추가
$env:Path += ";C:\flutter\bin"

# 영구적으로 PATH에 추가
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\flutter\bin", "Machine")
```

### 설정 확인

**새 PowerShell 창**을 열고 아래 명령어를 실행합니다:

```powershell
flutter --version
```

다음과 같이 출력되면 성공입니다:
```
Flutter 3.24.5 • channel stable • https://github.com/flutter/flutter.git
Framework • revision dec2ee5c1f (...)
Engine • revision a18df97ca5
Tools • Dart 3.5.4 • DevTools 2.37.3
```

---

## Git 설치

프로젝트를 클론하려면 Git이 필요합니다.

### Git 다운로드 및 설치

1. **👉 [Git for Windows 다운로드](https://git-scm.com/download/win)**
2. 다운로드된 설치 파일 실행
3. 설치 옵션은 기본값으로 진행 (Next 계속 클릭)
4. 설치 완료

### Git 설치 확인

```powershell
git --version
# git version 2.x.x 출력되면 성공
```

---

## 프로젝트 실행

### 1단계: Flutter 환경 점검

```powershell
flutter doctor
```

웹 개발에 필요한 항목만 체크되면 됩니다:
```
[✓] Flutter (Channel stable, 3.24.5, ...)
[✓] Chrome - develop for the web
```

> 💡 Android/iOS 관련 경고는 웹 실행에는 영향 없으므로 무시해도 됩니다.

### 2단계: 프로젝트 클론

```powershell
# 원하는 폴더로 이동 (예: 문서 폴더)
cd $env:USERPROFILE\Documents

# 프로젝트 클론
git clone <repository-url>

# 프로젝트 폴더로 이동
cd interpreter_front
```

또는 ZIP 파일로 받은 경우:
```powershell
# 압축 해제한 폴더로 이동
cd C:\path\to\interpreter_front
```

### 3단계: 의존성 설치

```powershell
flutter pub get
```

출력 예시:
```
Resolving dependencies...
Got dependencies!
```

### 4단계: 웹 서버로 실행

```powershell
flutter run -d web-server --web-port=8080 --web-hostname=localhost
```

실행 성공 시 출력:
```
Launching lib/main.dart on Web Server in debug mode...
lib/main.dart is being served at http://localhost:8080
```

### 5단계: 브라우저에서 확인

Chrome, Edge 등 브라우저를 열고 아래 주소로 접속:

```
http://localhost:8080
```

---

## 🎉 실행 완료!

앱이 브라우저에 표시되면 성공입니다!

### 앱 사용 흐름

1. **스플래시** → 자동으로 웰컴 화면 이동
2. **웰컴** → "시작하기" 클릭
3. **온보딩** → 3페이지 확인 또는 "건너뛰기"
4. **로그인** → "테스트용 빠른 로그인" 클릭
5. **대시보드** → "검사 시작" 클릭
7. **결과** → 존재 유형 분석 확인

### 개발 중 단축키

터미널에서 앱이 실행 중일 때:

| 키 | 동작 |
|----|------|
| `r` | Hot Restart (변경사항 반영) |
| `q` | 앱 종료 |
| `h` | 도움말 |

---

## 문제 해결

### ❌ 'flutter'은(는) 내부 또는 외부 명령... 이 아닙니다

**원인**: PATH 환경 변수가 설정되지 않았습니다.

**해결**:
1. 새 PowerShell 창을 엽니다 (환경 변수 적용을 위해)
2. PATH 설정을 다시 확인합니다
3. 또는 전체 경로로 실행합니다:
   ```powershell
   C:\flutter\bin\flutter --version
   ```

### ❌ 포트 8080 사용 중

**해결**: 다른 포트로 실행
```powershell
flutter run -d web-server --web-port=3000 --web-hostname=localhost
# 브라우저에서 http://localhost:3000 접속
```

또는 사용 중인 프로세스 종료:
```powershell
# 8080 포트 사용 중인 프로세스 확인
netstat -ano | findstr :8080

# PID 확인 후 종료 (예: PID가 1234인 경우)
taskkill /PID 1234 /F
```

### ❌ flutter pub get 실패

**해결**:
```powershell
# 캐시 정리 후 재시도
flutter clean
flutter pub get
```

### ❌ 웹 빌드 에러

**해결**:
```powershell
# 웹 지원 활성화
flutter config --enable-web

# 다시 실행
flutter run -d chrome
```

### ❌ Chrome이 없다는 에러

**해결**:
1. Chrome 브라우저 설치: https://www.google.com/chrome/
2. 또는 Edge 사용:
   ```powershell
   flutter run -d edge
   ```

### ❌ Git clone 실패

**해결**: Git이 설치되어 있는지 확인
```powershell
git --version
```

설치되어 있지 않다면 [Git 설치](#git-설치) 섹션 참조

---

## 추가 도구 (선택사항)

### VS Code 설치 (권장 IDE)

1. **👉 [VS Code 다운로드](https://code.visualstudio.com/)**
2. 설치 후 Flutter 확장 설치:
   - VS Code 실행
   - `Ctrl + Shift + X` (확장 마켓플레이스)
   - "Flutter" 검색 후 설치

### Android Studio 설치 (Android 빌드 시 필요)

1. **👉 [Android Studio 다운로드](https://developer.android.com/studio)**
2. 설치 후 Flutter/Dart 플러그인 설치

---

## 전체 명령어 요약

```powershell
# 1. Flutter 버전 확인
flutter --version

# 2. 환경 점검
flutter doctor

# 3. 프로젝트 폴더로 이동
cd C:\path\to\interpreter_front

# 4. 의존성 설치
flutter pub get

# 5. 웹으로 실행
flutter run -d web-server --web-port=8080 --web-hostname=localhost

# 6. 브라우저에서 http://localhost:8080 접속
```

---

## 도움이 필요하면?

- 공식 Flutter 문서: https://docs.flutter.dev
- Flutter 커뮤니티: https://flutter.dev/community
- 프로젝트 담당자에게 문의

