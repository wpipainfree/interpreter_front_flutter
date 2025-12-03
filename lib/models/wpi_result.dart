class WpiResult {
  final String existenceType;
  final String coreMessage;
  final double redLineValue;
  final String redLineDescription;
  final double blueLineValue;
  final String blueLineDescription;
  final String gapAnalysis;
  final List<String> emotionalSignals;
  final List<String> bodySignals;

  const WpiResult({
    required this.existenceType,
    required this.coreMessage,
    required this.redLineValue,
    required this.redLineDescription,
    required this.blueLineValue,
    required this.blueLineDescription,
    required this.gapAnalysis,
    required this.emotionalSignals,
    required this.bodySignals,
  });
}
