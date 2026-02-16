import '../../common/failure.dart';
import '../../common/result.dart';
import '../../domain/model/auth_user.dart';
import '../../domain/model/signup_request.dart';
import '../../domain/model/terms.dart';
import '../../domain/repository/auth_repository.dart';
import '../../services/auth_service.dart' as auth;

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({auth.AuthService? authService})
      : _authService = authService ?? auth.AuthService();

  final auth.AuthService _authService;

  @override
  Future<Result<AuthUser>> loginWithSocial(String provider) async {
    final raw = await _authService.loginWithSocial(provider);
    return _mapAuthResult(
      raw,
      fallbackMessage: '소셜 로그인에 실패했습니다.',
    );
  }

  @override
  Future<Result<AuthUser>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final raw = await _authService.loginWithEmail(email, password);
    return _mapAuthResult(
      raw,
      fallbackMessage: '이메일 로그인에 실패했습니다.',
    );
  }

  @override
  Future<Result<AuthUser>> loginAsGuest() async {
    final raw = await _authService.loginAsGuest();
    return _mapAuthResult(
      raw,
      fallbackMessage: '게스트 로그인에 실패했습니다.',
    );
  }

  @override
  Future<Result<TermsBundle>> getCurrentTerms({
    String serviceCode = 'PAINFREE_WEB',
    String channelCode = 'WEB',
    List<String> termTypes = const ['TERMS', 'PRIVACY', 'MARKETING'],
    String contentFormat = 'auto',
  }) async {
    final raw = await _authService.getCurrentTerms(
      serviceCode: serviceCode,
      channelCode: channelCode,
      termTypes: termTypes,
      contentFormat: contentFormat,
    );
    if (raw.isSuccess && raw.bundle != null) {
      return Result.success(_mapTermsBundle(raw.bundle!));
    }

    return Result.failure(
      Failure(
        userMessage: _fallback(
          raw.errorMessage,
          '약관 정보를 불러오지 못했습니다.',
        ),
        code: 'TERMS_FETCH_FAILED',
        debugMessage: raw.debugMessage,
      ),
    );
  }

  @override
  Future<Result<AuthUser>> signUp(SignUpRequest request) async {
    final raw = await _authService.signUp(
      email: request.email,
      password: request.password,
      name: request.name,
      gender: request.gender,
      birthdayYmd: request.birthdayYmd,
      termsAgreed: request.termsAgreed,
      privacyAgreed: request.privacyAgreed,
      marketingAgreed: request.marketingAgreed,
      serviceCode: request.serviceCode,
      channelCode: request.channelCode,
      mobileNumber: request.mobileNumber,
    );
    return _mapAuthResult(
      raw,
      fallbackMessage: '회원가입에 실패했습니다.',
    );
  }

  @override
  Future<Result<TermsAgreementSaveSummary>> saveTermsAgreements({
    required String serviceCode,
    required String channelCode,
    required List<TermsAgreementItem> agreements,
    String source = 'settings',
  }) async {
    final raw = await _authService.saveTermsAgreements(
      serviceCode: serviceCode,
      channelCode: channelCode,
      source: source,
      agreements: agreements
          .map(
            (item) => auth.TermsAgreementItem(
              termsType: item.termsType,
              agreed: item.agreed,
            ),
          )
          .toList(),
    );

    if (raw.isSuccess) {
      return Result.success(
        TermsAgreementSaveSummary(
          message: raw.message,
          insertedCount: raw.insertedCount,
          updatedCount: raw.updatedCount,
          missingTermTypes: raw.missingTermTypes,
        ),
      );
    }

    return Result.failure(
      Failure(
        userMessage: _fallback(
          raw.errorMessage,
          '약관 동의 저장에 실패했습니다.',
        ),
        code: raw.errorCode ?? 'TERMS_SAVE_FAILED',
        debugMessage: raw.debugMessage,
      ),
    );
  }

  Result<AuthUser> _mapAuthResult(
    auth.AuthResult raw, {
    required String fallbackMessage,
  }) {
    if (raw.isSuccess && raw.user != null) {
      return Result.success(_mapUser(raw.user!));
    }

    return Result.failure(
      Failure(
        userMessage: _fallback(raw.errorMessage, fallbackMessage),
        code: raw.errorCode ?? 'AUTH_FAILED',
        debugMessage: raw.debugMessage,
      ),
    );
  }

  AuthUser _mapUser(auth.UserInfo raw) {
    return AuthUser(
      id: raw.id,
      email: raw.email,
      name: raw.name,
      provider: raw.provider,
      linkedProviders: raw.linkedProviders,
    );
  }

  TermsBundle _mapTermsBundle(auth.CurrentTermsBundle raw) {
    return TermsBundle(
      serviceCode: raw.serviceCode,
      channelCode: raw.channelCode,
      contentFormat: raw.contentFormat,
      terms: raw.terms.map(_mapTerm).toList(),
      missingTermTypes: raw.missingTermTypes,
    );
  }

  TermsDocument _mapTerm(auth.TermsDocument raw) {
    return TermsDocument(
      termsType: raw.termsType,
      termsVerId: raw.termsVerId,
      requiredYn: raw.requiredYn,
      termsExplain: raw.termsExplain,
      content: raw.content,
      contentFormat: raw.contentFormat,
      applyStartYmd: raw.applyStartYmd,
      effectiveYmd: raw.effectiveYmd,
    );
  }

  String _fallback(String? raw, String defaultValue) {
    if (raw == null || raw.trim().isEmpty) return defaultValue;
    return raw;
  }
}
