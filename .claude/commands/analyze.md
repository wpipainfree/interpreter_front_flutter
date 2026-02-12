# Flutter 코드 분석

Flutter 코드 정적 분석을 실행합니다.

## 사용법
```
/analyze
```

## 실행 명령

```bash
flutter analyze
```

## 분석 결과

분석 후 다음을 확인하세요:

1. **에러 (Errors)**: 반드시 수정해야 하는 문제
2. **경고 (Warnings)**: 권장 수정 사항
3. **정보 (Infos)**: 스타일 가이드 관련

에러나 경고가 있으면 해당 파일과 라인 번호를 포함하여 수정 방법을 제안하세요.

## 분석 옵션 (analysis_options.yaml)

이 프로젝트의 린트 규칙은 `analysis_options.yaml`에 정의되어 있습니다.
