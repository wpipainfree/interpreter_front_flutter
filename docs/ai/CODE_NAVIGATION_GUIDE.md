# Code Navigation Guide

AI가 수정 범위를 빠르게 찾기 위한 코드 내비게이션 문서입니다.

## Table of Contents

1. [프로젝트 진입점](#프로젝트-진입점)
2. [아키텍처 공통 축](#아키텍처-공통-축)
3. [기능별 코드 위치](#기능별-코드-위치)
4. [문제 유형별 시작 파일](#문제-유형별-시작-파일)
5. [테스트 위치](#테스트-위치)

## 프로젝트 진입점

1. 앱 시작/전역 초기화: `lib/main.dart`
2. 라우트 상수/인자: `lib/router/app_routes.dart`
3. 라우트 매핑: `lib/router/app_router.dart`
4. 의존성 조합(Composition Root): `lib/app/di/app_scope.dart`
5. UI-서비스 경계 검사: `tool/check_ui_service_boundary.dart`
6. CI 품질 게이트: `.github/workflows/flutter_analyze.yml`

## 아키텍처 공통 축

1. UI: `lib/screens/**`
2. ViewModel: `lib/ui/**`
3. Domain:
   - 모델: `lib/domain/model/**`
   - 인터페이스: `lib/domain/repository/**`
   - 유스케이스: `lib/domain/usecase/**`
4. Data 구현: `lib/data/repository/**`
5. IO 서비스: `lib/services/**`
6. 테스트 더블(Fake): `test/testing/fakes/**`

## 기능별 코드 위치

### Auth

- Screen: `lib/screens/auth/login_screen.dart`, `lib/screens/auth/email_login_screen.dart`, `lib/screens/auth/signup_screen.dart`
- ViewModel: `lib/ui/auth/view_models/login_view_model.dart`, `lib/ui/auth/view_models/email_login_view_model.dart`, `lib/ui/auth/view_models/signup_view_model.dart`, `lib/ui/auth/view_models/terms_agreement_settings_view_model.dart`
- Domain/Data: `lib/domain/repository/auth_repository.dart`, `lib/data/repository/auth_repository_impl.dart`
- Tests: `test/unit/ui/auth/login_view_model_test.dart`, `test/unit/ui/auth/signup_view_model_test.dart`

### Dashboard

- Screen: `lib/screens/dashboard_screen.dart`
- ViewModel: `lib/ui/dashboard/dashboard_view_model.dart`
- Domain/Data: `lib/domain/repository/dashboard_repository.dart`, `lib/data/repository/dashboard_repository_impl.dart`
- Model: `lib/domain/model/dashboard_models.dart`
- Tests: `test/unit/ui/dashboard/dashboard_view_model_test.dart`

### Result

- Screen: `lib/screens/result/user_result_single_screen.dart`, `lib/screens/result/user_result_detail_screen.dart`
- ViewModel: `lib/ui/result/view_models/user_result_single_view_model.dart`, `lib/ui/result/view_models/user_result_detail_view_model.dart`
- Domain/Data: `lib/domain/repository/result_repository.dart`, `lib/data/repository/result_repository_impl.dart`
- Tests: `test/unit/ui/result/user_result_single_view_model_test.dart`, `test/unit/ui/result/user_result_detail_view_model_test.dart`

### WPI Test Flow

- Screen: `lib/screens/test/wpi_selection_flow_new.dart`, `lib/screens/test/wpi_selection_screen.dart`, `lib/screens/test/wpi_review_screen.dart`
- ViewModel: `lib/ui/test/wpi_selection_flow_view_model.dart`, `lib/ui/test/wpi_selection_view_model.dart`, `lib/ui/test/wpi_review_view_model.dart`
- Domain:
  - Repository: `lib/domain/repository/psych_test_repository.dart`
  - Use-case: `lib/domain/usecase/wpi_selection_use_case.dart`
  - Model: `lib/domain/model/psych_test_models.dart`, `lib/domain/model/wpi_flow_state.dart`
- Data: `lib/data/repository/psych_test_repository_impl.dart`
- Unit Tests:
  - `test/unit/ui/test/wpi_selection_flow_view_model_test.dart`
  - `test/unit/ui/test/wpi_selection_view_model_test.dart`
  - `test/unit/ui/test/wpi_review_view_model_test.dart`
  - `test/unit/domain/usecase/wpi_selection_use_case_test.dart`
  - `test/unit/domain/model/wpi_flow_state_test.dart`
- Widget Tests:
  - `test/widget/screens/test/wpi_selection_flow_new_test.dart`
  - `test/widget/screens/test/wpi_selection_screen_test.dart`
  - `test/widget/screens/test/wpi_review_screen_test.dart`

### Profile / Settings / Main Shell

- Screen:
  - `lib/screens/profile/my_page_screen.dart`
  - `lib/screens/profile/payment_history_screen.dart`
  - `lib/screens/settings/notification_settings_screen.dart`
  - `lib/screens/main_shell.dart`
- ViewModel:
  - `lib/ui/profile/my_page_view_model.dart`
  - `lib/ui/profile/payment_history_view_model.dart`
  - `lib/ui/settings/notification_settings_view_model.dart`
  - `lib/ui/main/main_shell_view_model.dart`
- Domain/Data:
  - `lib/domain/repository/profile_repository.dart` / `lib/data/repository/profile_repository_impl.dart`
  - `lib/domain/repository/payment_repository.dart` / `lib/data/repository/payment_repository_impl.dart`
  - `lib/domain/repository/notification_repository.dart` / `lib/data/repository/notification_repository_impl.dart`
- Tests:
  - `test/unit/ui/profile/my_page_view_model_test.dart`
  - `test/unit/ui/profile/payment_history_view_model_test.dart`
  - `test/unit/ui/settings/notification_settings_view_model_test.dart`
  - `test/unit/ui/main/main_shell_view_model_test.dart`

## 문제 유형별 시작 파일

1. 라우팅/인자 오류:
   - `lib/router/app_routes.dart`
   - `lib/router/app_router.dart`
2. 로그인 상태/세션 반영 오류:
   - `lib/main.dart`
   - `lib/services/auth_service.dart`
   - `lib/ui/main/main_shell_view_model.dart`
3. 결제 흐름 오류:
   - `lib/screens/dashboard_screen.dart`
   - `lib/screens/payment/payment_webview_screen.dart`
   - `lib/domain/repository/payment_repository.dart`
4. WPI 검사 흐름 오류:
   - `lib/screens/test/**`
   - `lib/ui/test/**`
   - `lib/domain/usecase/wpi_selection_use_case.dart`
5. 경계 위반 오류(화면에서 service import):
   - `tool/check_ui_service_boundary.dart`
   - `lib/screens/**` import 구문

## 테스트 위치

1. Unit 테스트 루트: `test/unit/**`
2. Widget 테스트 루트: `test/widget/**`
3. Fake 저장소: `test/testing/fakes/**`
4. 회귀 확인용 공통 테스트:
   - `test/openai_interpret_response_test.dart`
   - `test/user_account_item_test.dart`
