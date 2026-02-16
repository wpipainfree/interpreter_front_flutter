import '../../../common/result.dart';
import '../../../domain/model/auth_user.dart';
import '../../../domain/model/signup_request.dart';
import '../../../domain/model/terms.dart';
import '../../../domain/repository/auth_repository.dart';

class SignUpViewModel {
  SignUpViewModel(this._authRepository);

  final AuthRepository _authRepository;

  Future<Result<TermsBundle>> loadCurrentTerms({
    String serviceCode = 'PAINFREE_WEB',
    String channelCode = 'WEB',
    List<String> termTypes = const ['TERMS', 'PRIVACY', 'MARKETING'],
    String contentFormat = 'auto',
  }) {
    return _authRepository.getCurrentTerms(
      serviceCode: serviceCode,
      channelCode: channelCode,
      termTypes: termTypes,
      contentFormat: contentFormat,
    );
  }

  Future<Result<AuthUser>> signUp(SignUpRequest request) {
    return _authRepository.signUp(request);
  }
}
