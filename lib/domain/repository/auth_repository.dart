import '../../common/result.dart';
import '../model/auth_user.dart';
import '../model/signup_request.dart';
import '../model/terms.dart';

abstract interface class AuthRepository {
  Future<Result<AuthUser>> loginWithSocial(String provider);

  Future<Result<AuthUser>> loginWithEmail({
    required String email,
    required String password,
  });

  Future<Result<AuthUser>> loginAsGuest();

  Future<Result<TermsBundle>> getCurrentTerms({
    String serviceCode = 'PAINFREE_WEB',
    String channelCode = 'WEB',
    List<String> termTypes = const ['TERMS', 'PRIVACY', 'MARKETING'],
    String contentFormat = 'auto',
  });

  Future<Result<AuthUser>> signUp(SignUpRequest request);

  Future<Result<TermsAgreementSaveSummary>> saveTermsAgreements({
    required String serviceCode,
    required String channelCode,
    required List<TermsAgreementItem> agreements,
    String source = 'settings',
  });
}
