# Flutter 테스트 실행

Flutter 테스트를 실행합니다.

## 사용법
```
/test [path]
```

## 인자
$ARGUMENTS

- `path` (선택): 특정 테스트 파일 또는 디렉토리 경로
  - 미지정시 전체 테스트 실행

## 실행 명령

1. **전체 테스트**: `flutter test`
2. **특정 파일**: `flutter test test/widget_test.dart`
3. **특정 디렉토리**: `flutter test test/unit/`

## 테스트 옵션

- 커버리지 포함: `flutter test --coverage`
- 특정 테스트만: `flutter test --name "test name"`

테스트 실행 후 결과를 요약해서 보여주세요:
- 통과/실패 테스트 수
- 실패한 테스트가 있으면 상세 정보 제공
