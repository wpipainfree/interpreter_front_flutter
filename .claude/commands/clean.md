# Flutter 프로젝트 클린

Flutter 프로젝트의 빌드 캐시를 정리합니다.

## 사용법
```
/clean
```

## 실행 명령

```bash
flutter clean && flutter pub get
```

## 정리 대상

- `build/` 디렉토리
- `.dart_tool/` 디렉토리
- 플랫폼별 빌드 캐시

클린 후 자동으로 `flutter pub get`을 실행하여 의존성을 다시 설치합니다.

## 언제 사용하나요?

- 빌드 에러가 지속될 때
- 의존성 충돌 문제
- 플랫폼 네이티브 코드 변경 후
- 브랜치 전환 후 빌드 문제
