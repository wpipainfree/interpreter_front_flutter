class TermsBundle {
  const TermsBundle({
    required this.serviceCode,
    required this.channelCode,
    required this.contentFormat,
    required this.terms,
    required this.missingTermTypes,
  });

  final String serviceCode;
  final String channelCode;
  final String contentFormat;
  final List<TermsDocument> terms;
  final List<String> missingTermTypes;

  TermsDocument? termByType(String type) {
    final normalized = type.toUpperCase();
    for (final term in terms) {
      if (term.termsType.toUpperCase() == normalized) {
        return term;
      }
    }
    return null;
  }
}

class TermsDocument {
  const TermsDocument({
    required this.termsType,
    required this.termsVerId,
    required this.requiredYn,
    required this.termsExplain,
    required this.content,
    required this.contentFormat,
    required this.applyStartYmd,
    required this.effectiveYmd,
  });

  final String termsType;
  final String termsVerId;
  final bool requiredYn;
  final String termsExplain;
  final String content;
  final String contentFormat;
  final String applyStartYmd;
  final String effectiveYmd;
}

class TermsAgreementItem {
  const TermsAgreementItem({
    required this.termsType,
    required this.agreed,
  });

  final String termsType;
  final bool agreed;
}

class TermsAgreementSaveSummary {
  const TermsAgreementSaveSummary({
    this.message,
    this.insertedCount = 0,
    this.updatedCount = 0,
    this.missingTermTypes = const [],
  });

  final String? message;
  final int insertedCount;
  final int updatedCount;
  final List<String> missingTermTypes;
}
