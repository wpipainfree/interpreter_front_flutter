import 'package:wpi_app/common/failure.dart';
import 'package:wpi_app/common/result.dart';
import 'package:wpi_app/domain/model/auth_user.dart';
import 'package:wpi_app/domain/model/signup_request.dart';
import 'package:wpi_app/domain/model/terms.dart';
import 'package:wpi_app/domain/repository/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  Result<AuthUser> socialLoginResult = Result.failure(
    const Failure(userMessage: 'social login not configured'),
  );
  Result<AuthUser> emailLoginResult = Result.failure(
    const Failure(userMessage: 'email login not configured'),
  );
  Result<AuthUser> guestLoginResult = Result.failure(
    const Failure(userMessage: 'guest login not configured'),
  );
  Result<TermsBundle> currentTermsResult = Result.failure(
    const Failure(userMessage: 'terms not configured'),
  );
  Result<AuthUser> signUpResult = Result.failure(
    const Failure(userMessage: 'signup not configured'),
  );
  Result<TermsAgreementSaveSummary> saveTermsAgreementsResult = Result.failure(
    const Failure(userMessage: 'save terms not configured'),
  );

  @override
  Future<Result<AuthUser>> loginWithSocial(String provider) async {
    return socialLoginResult;
  }

  @override
  Future<Result<AuthUser>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    return emailLoginResult;
  }

  @override
  Future<Result<AuthUser>> loginAsGuest() async {
    return guestLoginResult;
  }

  @override
  Future<Result<TermsBundle>> getCurrentTerms({
    String serviceCode = 'PAINFREE_WEB',
    String channelCode = 'WEB',
    List<String> termTypes = const ['TERMS', 'PRIVACY', 'MARKETING'],
    String contentFormat = 'auto',
  }) async {
    return currentTermsResult;
  }

  @override
  Future<Result<AuthUser>> signUp(SignUpRequest request) async {
    return signUpResult;
  }

  @override
  Future<Result<TermsAgreementSaveSummary>> saveTermsAgreements({
    required String serviceCode,
    required String channelCode,
    required List<TermsAgreementItem> agreements,
    String source = 'settings',
  }) async {
    return saveTermsAgreementsResult;
  }
}
