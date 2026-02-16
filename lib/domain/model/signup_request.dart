class SignUpRequest {
  const SignUpRequest({
    required this.email,
    required this.password,
    required this.name,
    required this.gender,
    required this.birthdayYmd,
    required this.termsAgreed,
    required this.privacyAgreed,
    required this.marketingAgreed,
    required this.serviceCode,
    required this.channelCode,
    this.mobileNumber,
  });

  final String email;
  final String password;
  final String name;
  final String gender;
  final String birthdayYmd;
  final bool termsAgreed;
  final bool privacyAgreed;
  final bool marketingAgreed;
  final String serviceCode;
  final String channelCode;
  final String? mobileNumber;
}
