import 'package:flutter_test/flutter_test.dart';
import 'package:wpi_app/common/failure.dart';
import 'package:wpi_app/common/result.dart';
import 'package:wpi_app/domain/model/auth_user.dart';
import 'package:wpi_app/domain/model/signup_request.dart';
import 'package:wpi_app/domain/model/terms.dart';
import 'package:wpi_app/ui/auth/view_models/signup_view_model.dart';

import '../../../testing/fakes/fake_auth_repository.dart';

void main() {
  group('SignUpViewModel', () {
    test('loadCurrentTerms returns bundle from repository', () async {
      const bundle = TermsBundle(
        serviceCode: 'PAINFREE_WEB',
        channelCode: 'WEB',
        contentFormat: 'auto',
        terms: [
          TermsDocument(
            termsType: 'TERMS',
            termsVerId: 'v1',
            requiredYn: true,
            termsExplain: '필수 약관',
            content: 'content',
            contentFormat: 'markdown',
            applyStartYmd: '20260101',
            effectiveYmd: '20260101',
          ),
        ],
        missingTermTypes: [],
      );
      final fake = FakeAuthRepository()
        ..currentTermsResult = Result.success(bundle);
      final viewModel = SignUpViewModel(fake);

      final result = await viewModel.loadCurrentTerms();

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?.serviceCode, 'PAINFREE_WEB');
      expect(result.valueOrNull?.terms.length, 1);
    });

    test('signUp forwards failure from repository', () async {
      final fake = FakeAuthRepository()
        ..signUpResult = Result.failure(
          const Failure(
            userMessage: '이미 가입된 이메일입니다.',
            code: 'EMAIL_ALREADY_EXISTS',
          ),
        );
      final viewModel = SignUpViewModel(fake);

      const request = SignUpRequest(
        email: 'user@example.com',
        password: 'Password!1',
        name: 'Tester',
        gender: '남',
        birthdayYmd: '19990101',
        termsAgreed: true,
        privacyAgreed: true,
        marketingAgreed: false,
        serviceCode: 'PAINFREE_WEB',
        channelCode: 'WEB',
      );
      final result = await viewModel.signUp(request);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.code, 'EMAIL_ALREADY_EXISTS');
      expect(result.failureOrNull?.userMessage, '이미 가입된 이메일입니다.');
    });

    test('signUp forwards success from repository', () async {
      final fake = FakeAuthRepository()
        ..signUpResult = Result.success(
          const AuthUser(id: '10', email: 'user@example.com', name: 'Tester'),
        );
      final viewModel = SignUpViewModel(fake);

      const request = SignUpRequest(
        email: 'user@example.com',
        password: 'Password!1',
        name: 'Tester',
        gender: '남',
        birthdayYmd: '19990101',
        termsAgreed: true,
        privacyAgreed: true,
        marketingAgreed: false,
        serviceCode: 'PAINFREE_WEB',
        channelCode: 'WEB',
      );
      final result = await viewModel.signUp(request);

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?.email, 'user@example.com');
    });
  });
}
