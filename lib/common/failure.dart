class Failure {
  const Failure({
    required this.userMessage,
    this.code = 'UNKNOWN',
    this.debugMessage,
  });

  final String userMessage;
  final String code;
  final String? debugMessage;

  bool hasCode(String expectedCode) {
    return code.toUpperCase() == expectedCode.toUpperCase();
  }
}
