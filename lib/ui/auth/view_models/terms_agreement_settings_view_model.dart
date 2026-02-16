import '../../../common/result.dart';
import '../../../domain/model/terms.dart';
import '../../../domain/repository/auth_repository.dart';

class TermsAgreementSettingsViewModel {
  TermsAgreementSettingsViewModel(this._authRepository);

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

  Future<Result<TermsAgreementSaveSummary>> saveTermsAgreements({
    required String serviceCode,
    required String channelCode,
    required List<TermsAgreementItem> agreements,
    String source = 'settings',
  }) {
    return _authRepository.saveTermsAgreements(
      serviceCode: serviceCode,
      channelCode: channelCode,
      agreements: agreements,
      source: source,
    );
  }
}
