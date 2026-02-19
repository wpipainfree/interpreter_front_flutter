# Architecture + Test Guide

AI 코드 작성 시 반드시 지켜야 하는 아키텍처 경계와 테스트 기준입니다.

## Table of Contents

1. [기본 아키텍처](#기본-아키텍처)
2. [레이어별 의존 규칙](#레이어별-의존-규칙)
3. [변경 유형별 필수 테스트](#변경-유형별-필수-테스트)
4. [실행 커맨드](#실행-커맨드)
5. [작업 완료 기준](#작업-완료-기준)

## 기본 아키텍처

```text
UI (screens/widgets)
  -> ViewModel (ui/*)
    -> (Optional) Use-case (domain/usecase/*)
      -> Repository Interface (domain/repository/*)
        -> Repository Impl (data/repository/*)
          -> Service (services/* IO)
```

핵심 원칙:

1. 화면(`lib/screens`)은 직접 `lib/services`를 import하지 않습니다.
2. ViewModel/Use-case는 `BuildContext`에 의존하지 않습니다.
3. 외부 의존성은 생성자 주입으로 교체 가능해야 합니다.
4. 복합 비즈니스 규칙은 ViewModel에서 분리해 Use-case로 옮깁니다.

## 레이어별 의존 규칙

| 레이어 | 주 경로 | 허용 의존 | 금지 의존 | 필수 테스트 |
|---|---|---|---|---|
| UI View | `lib/screens/**` | ViewModel, 라우팅, UI 위젯 | `lib/services/**` 직접 import | Widget test |
| ViewModel | `lib/ui/**` | domain model/repository/usecase | `BuildContext`, Widget tree 조작 | Unit test |
| Domain Use-case | `lib/domain/usecase/**` | domain model/repository interface | data/service 구체 구현 | Unit test |
| Repository Interface | `lib/domain/repository/**` | domain model | Flutter UI, service 직접 구현 | 계약(시그니처) 유지 |
| Repository Impl | `lib/data/repository/**` | domain interface, services | screen/viewmodel 참조 | Unit test 또는 상위 ViewModel 회귀 테스트 |
| Service(IO) | `lib/services/**` | API client, 플랫폼 SDK | UI 상태 로직 | 최소 smoke + 호출 경로 테스트 |

경계 강제 도구:

- `tool/check_ui_service_boundary.dart`
- CI: `.github/workflows/flutter_analyze.yml`

## 변경 유형별 필수 테스트

| 변경 유형 | 최소 필수 테스트 | 권장 추가 테스트 |
|---|---|---|
| 화면(UI) 렌더링/상호작용 변경 | 해당 화면 Widget test | 실패 시나리오(에러뷰/스낵바) 추가 |
| ViewModel 로직/상태 전이 변경 | 해당 ViewModel Unit test | 예외 경로(rethrow/error mapping) |
| Use-case 추가/변경 | Use-case Unit test | 다중 입력 케이스(경계값) |
| Repository Impl 매핑/예외 처리 변경 | 연결된 ViewModel Unit test(회귀) | Repository 단위 테스트 |
| 라우팅(AppRoutes/AppRouter) 변경 | 라우트 인자/화면 진입 테스트 | 잘못된 args 에러 경로 검증 |
| DI(AppScope) 변경 | 관련 Unit/Widget smoke test | 로그인 상태 변화 이벤트 테스트 |

실패 시나리오 최소 세트:

1. 네트워크/IO 예외 발생
2. 필수 데이터 누락(예: result id 없음)
3. 인증 만료/로그인 필요 상태
4. 재시도 가능 상태에서 UI가 복구되는지

## 실행 커맨드

전체 품질 게이트:

```bash
dart run tool/check_ui_service_boundary.dart --all
flutter analyze --no-fatal-infos
flutter test
```

빠른 범위 확인(예시):

```bash
flutter test test/unit/ui/test/wpi_selection_flow_view_model_test.dart
flutter test test/widget/screens/test/wpi_selection_flow_new_test.dart
dart run tool/check_ui_service_boundary.dart --path lib/screens/test
```

## 작업 완료 기준

아래를 모두 만족해야 완료로 봅니다.

1. 경계 규칙 위반 없음 (`check_ui_service_boundary` 통과)
2. 변경된 로직에 대응하는 unit/widget 테스트가 존재하고 통과
3. `flutter analyze --no-fatal-infos`에서 error 없음
4. `flutter test` 전체 통과
5. 문서 갱신 완료 (`docs/ai/*`, `docs/아키텍처_개선_실행_가이드.md`)
