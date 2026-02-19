# Document Maintenance Guide

AI 작업 완료 후 어떤 문서를 어떻게 갱신할지 정리한 운영 문서입니다.

## Table of Contents

1. [갱신 원칙](#갱신-원칙)
2. [작업 유형별 수정 문서](#작업-유형별-수정-문서)
3. [완료 후 문서 업데이트 절차](#완료-후-문서-업데이트-절차)
4. [완료 로그 템플릿](#완료-로그-템플릿)
5. [문서 품질 체크리스트](#문서-품질-체크리스트)

## 갱신 원칙

1. 코드가 바뀌면 문서도 같은 PR/커밋 범위에서 같이 업데이트합니다.
2. 문서에는 "무엇을/왜/어떻게/어디를 검증했는지"를 반드시 남깁니다.
3. 실행하지 않은 검증은 "미실행"으로 명시합니다.
4. 경계 규칙, 테스트 명령, 파일 경로는 실제 저장소 기준으로 작성합니다.

## 작업 유형별 수정 문서

| 작업 유형 | 반드시 수정할 문서 | 필요 시 추가 수정 |
|---|---|---|
| 아키텍처 규칙 변경 | `docs/ai/ARCHITECTURE_TEST_GUIDE.md` | `docs/ai/README.md` |
| 파일 위치/구조 변경 | `docs/ai/CODE_NAVIGATION_GUIDE.md` | `docs/ai/README.md` |
| 완료 내역 기록 | `docs/아키텍처_개선_실행_가이드.md` | `docs/ai/README.md` |
| 검증/게이트 변경(CI, boundary script) | `docs/ai/ARCHITECTURE_TEST_GUIDE.md` | `.github/pull_request_template.md` 반영 확인 |
| 문서 운영 규칙 변경 | `docs/ai/DOCUMENT_MAINTENANCE_GUIDE.md` | 관련 문서 전부 |

## 완료 후 문서 업데이트 절차

1. 변경 범위를 요약합니다.
   - 영향 기능
   - 변경 파일
   - 동작/경계 영향
2. 실행한 검증을 정리합니다.
   - `dart run tool/check_ui_service_boundary.dart --all`
   - `flutter analyze --no-fatal-infos`
   - `flutter test`
   - 필요 시 타깃 테스트
3. `docs/아키텍처_개선_실행_가이드.md`에 최신 완료 로그를 추가합니다.
4. 아키텍처/내비게이션 문서의 경로와 테스트 매트릭스를 갱신합니다.
5. PR 체크리스트(`.github/pull_request_template.md`) 항목 충족 여부를 확인합니다.

## 완료 로그 템플릿

`docs/아키텍처_개선_실행_가이드.md`에 아래 형식으로 추가합니다.

```md
## NN. Additional Completion Log (YYYY-MM-DD, <Slice Name>)

- Status: Work completion confirmed (`작업 완료 확인`)
- Completed scope:
1. ...
2. ...
3. ...
- Validation results:
1. `dart run tool/check_ui_service_boundary.dart --all`: pass/fail
2. `flutter analyze --no-fatal-infos`: pass/fail
3. `flutter test`: pass/fail
```

규칙:

1. `NN`은 이전 섹션 번호 +1
2. 날짜는 절대 날짜(`YYYY-MM-DD`) 사용
3. 검증 결과는 실제 실행한 커맨드만 기록

## 문서 품질 체크리스트

1. 문서의 파일 경로가 실제 저장소와 일치하는가
2. 테스트 명령이 현재 CI와 충돌하지 않는가
3. 경계 규칙(`screens -> services direct import 금지`)이 반영되어 있는가
4. 새로 추가된 ViewModel/Use-case/Repository 경로가 내비게이션 문서에 포함되었는가
5. 완료 로그에 `작업 완료 확인` 문구가 포함되었는가
