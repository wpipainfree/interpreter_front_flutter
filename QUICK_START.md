# 🚀 빠른 시작 가이드

이 가이드는 프로젝트를 **5분 안에** 실행하는 방법을 설명합니다.

---

## 사전 준비

Flutter SDK가 이미 설치되어 있다면 [3단계](#3단계-프로젝트-실행)로 바로 이동하세요.

---

## 1단계: Flutter SDK 설치 (최초 1회)

### macOS

```bash
# 터미널에서 실행
cd ~

# M1/M2/M3 Mac인 경우
curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_arm64_3.24.5-stable.zip

# Intel Mac인 경우
curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_3.24.5-stable.zip

# 압축 해제
unzip flutter_macos_*.zip

# PATH 설정
echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### Windows

1. https://docs.flutter.dev/get-started/install/windows 에서 SDK 다운로드
2. `C:\flutter`에 압축 해제
3. 시스템 환경변수 PATH에 `C:\flutter\bin` 추가
4. 새 터미널 열기

---

## 2단계: 설치 확인

```bash
flutter --version
# Flutter 3.x.x 버전이 표시되면 성공!
```

---

## 3단계: 프로젝트 실행

```bash
# 1. 프로젝트 폴더로 이동
cd /path/to/interpreter_front_flutter

# 2. 의존성 설치
flutter pub get

# 3. 웹 서버로 실행
flutter run -d web-server --web-port=8080 --web-hostname=localhost
```

---

## 4단계: 브라우저에서 확인

브라우저를 열고 아래 주소로 접속:

```
http://localhost:8080
```

---

## 🎉 완료!

앱이 실행되면 다음 흐름을 따라가세요:

1. **스플래시 화면** → 자동으로 웰컴 화면으로 이동
2. **웰컴 화면** → "시작하기" 클릭
3. **온보딩** → 3페이지 확인 또는 "건너뛰기"
4. **로그인** → "테스트용 빠른 로그인" 클릭
5. **대시보드** → "검사 시작" 클릭
6. **WPI 검사** → 5문항 응답
7. **결과 확인** → 존재 유형 분석 확인

---

## 자주 발생하는 문제

### ❌ `flutter: command not found`

```bash
# PATH 다시 설정
export PATH="$HOME/flutter/bin:$PATH"
```

### ❌ 포트 8080 사용 중

```bash
# 기존 프로세스 종료
lsof -ti:8080 | xargs kill -9

# 또는 다른 포트 사용
flutter run -d web-server --web-port=3000 --web-hostname=localhost
```

### ❌ 패키지 에러

```bash
flutter clean
flutter pub get
```

---

## 개발 중 유용한 단축키

| 키 | 동작 |
|----|------|
| `r` | Hot Restart (변경사항 반영) |
| `R` | Hot Restart |
| `q` | 앱 종료 |
| `h` | 도움말 |

---

## 다음 단계

- 상세한 설명은 [README.md](./README.md) 참조
- 프로젝트 구조 이해하기
- 코드 수정 후 `r` 키로 변경사항 확인

