# AI Development Docs Hub

이 문서는 이 프로젝트에서 AI로 코드를 작성할 때 기준으로 삼는 문서의 인덱스입니다.

## Table of Contents

1. [Architecture + Test Guide](./ARCHITECTURE_TEST_GUIDE.md)
2. [Code Navigation Guide](./CODE_NAVIGATION_GUIDE.md)
3. [Document Maintenance Guide](./DOCUMENT_MAINTENANCE_GUIDE.md)
4. [기존 실행 로그 문서](../아키텍처_개선_실행_가이드.md)

## 5-Minute Start

1. 먼저 변경 유형을 분류합니다.
   - 화면(UI) 변경
   - ViewModel/Use-case 변경
   - Repository/Service 변경
   - 라우팅/DI 변경
2. [Architecture + Test Guide](./ARCHITECTURE_TEST_GUIDE.md)에서 해당 유형의 필수 테스트를 확인합니다.
3. [Code Navigation Guide](./CODE_NAVIGATION_GUIDE.md)에서 수정 대상 파일과 연관 테스트 위치를 찾습니다.
4. 구현 후 아래 품질 게이트를 통과시킵니다.
   - `dart run tool/check_ui_service_boundary.dart --all`
   - `flutter analyze --no-fatal-infos`
   - `flutter test`
5. 작업 완료 시 [Document Maintenance Guide](./DOCUMENT_MAINTENANCE_GUIDE.md) 절차대로 문서를 갱신합니다.

## Scope

- 이 문서는 `wpi_app`(`c:\Users\enjum\interpreter_front_flutter`) 기준입니다.
- 현재 아키텍처 방향: `MVVM + Repository/Service + (Optional) Use-case + Constructor DI`.
