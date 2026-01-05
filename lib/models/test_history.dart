import 'wpi_result.dart';

/// 검사 기록 모델
class TestHistory {
  final String id;
  final DateTime testDate;
  final String existenceType;
  final WpiResult result;
  final int questionCount;
  final Duration duration;

  const TestHistory({
    required this.id,
    required this.testDate,
    required this.existenceType,
    required this.result,
    this.questionCount = 60,
    this.duration = const Duration(minutes: 15),
  });
}
