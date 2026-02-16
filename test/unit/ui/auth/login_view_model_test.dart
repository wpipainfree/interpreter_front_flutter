import 'package:flutter_test/flutter_test.dart';
import 'package:wpi_app/common/failure.dart';
import 'package:wpi_app/common/result.dart';
import 'package:wpi_app/domain/model/auth_user.dart';
import 'package:wpi_app/ui/auth/view_models/login_view_model.dart';

import '../../../testing/fakes/fake_auth_repository.dart';

void main() {
  group('LoginViewModel', () {
    test('returns success when social login succeeds', () async {
      final fake = FakeAuthRepository()
        ..socialLoginResult = Result.success(
          const AuthUser(id: '1', email: 'test@example.com', name: 'Test'),
        );
      final viewModel = LoginViewModel(fake);

      final result = await viewModel.loginWithSocial('google');

      expect(result.action, LoginAction.success);
      expect(result.failure, isNull);
    });

    test('returns signupRequired when backend says USER_NOT_REGISTERED',
        () async {
      final fake = FakeAuthRepository()
        ..socialLoginResult = Result.failure(
          const Failure(
            userMessage: '등록되지 않은 사용자입니다.',
            code: 'USER_NOT_REGISTERED',
          ),
        );
      final viewModel = LoginViewModel(fake);

      final result = await viewModel.loginWithSocial('kakao');

      expect(result.action, LoginAction.signupRequired);
      expect(result.failure, isNull);
    });

    test('returns failed when guest login fails', () async {
      final fake = FakeAuthRepository()
        ..guestLoginResult = Result.failure(
          const Failure(
            userMessage: '게스트 로그인 실패',
            code: 'GUEST_LOGIN_FAILED',
          ),
        );
      final viewModel = LoginViewModel(fake);

      final result = await viewModel.loginAsGuest();

      expect(result.action, LoginAction.failed);
      expect(result.failure?.code, 'GUEST_LOGIN_FAILED');
      expect(result.failure?.userMessage, '게스트 로그인 실패');
    });
  });
}
