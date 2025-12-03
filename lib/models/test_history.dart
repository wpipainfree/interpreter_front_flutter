import 'wpi_result.dart';

/// 검사 이력 모델
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

  /// 테스트용 샘플 데이터 생성
  static List<TestHistory> getSampleHistory() {
    return [
      TestHistory(
        id: 'test_001',
        testDate: DateTime.now().subtract(const Duration(days: 2)),
        existenceType: '조화형',
        questionCount: 60,
        duration: const Duration(minutes: 18),
        result: const WpiResult(
          existenceType: '조화형',
          coreMessage: '당신은 내면의 기준과 자기 믿음이 균형을 이루고 있습니다. 안정적인 존재 구조를 가지고 있으며, 스트레스 상황에서도 비교적 유연하게 대처할 수 있습니다.',
          redLineValue: 0.68,
          redLineDescription: '자기 믿음이 안정적으로 유지됩니다. 스스로에 대한 신뢰가 적절한 수준입니다.',
          blueLineValue: 0.55,
          blueLineDescription: '내면화된 기준이 비교적 유연합니다. 상황에 따라 기준을 조절할 수 있습니다.',
          gapAnalysis: '두 지표 간 차이가 낮아 스트레스에 대한 회복력이 높습니다. 감정과 기준 사이의 균형이 잘 유지되고 있습니다.',
          emotionalSignals: ['안정감', '호기심', '차분함', '여유로움'],
          bodySignals: ['어깨 이완', '심박수 안정', '규칙적인 호흡', '편안한 수면'],
        ),
      ),
      TestHistory(
        id: 'test_002',
        testDate: DateTime.now().subtract(const Duration(days: 30)),
        existenceType: '도전형',
        questionCount: 60,
        duration: const Duration(minutes: 22),
        result: const WpiResult(
          existenceType: '도전형',
          coreMessage: '당신은 높은 기준을 세우고 그것을 향해 끊임없이 나아가는 존재 구조를 가지고 있습니다. 성취 지향적이며 자기 발전에 대한 욕구가 강합니다.',
          redLineValue: 0.82,
          redLineDescription: '자기 믿음이 매우 강합니다. 스스로에 대한 기대치가 높은 편입니다.',
          blueLineValue: 0.45,
          blueLineDescription: '내면화된 기준이 다소 엄격합니다. 완벽을 추구하는 경향이 있습니다.',
          gapAnalysis: '두 지표 간 차이가 있어 때때로 내적 긴장을 경험할 수 있습니다. 자기 기대와 현실 사이에서 균형을 찾는 것이 중요합니다.',
          emotionalSignals: ['열정', '긴장감', '성취욕', '조급함'],
          bodySignals: ['어깨 긴장', '가슴 답답함', '불규칙한 수면', '두통'],
        ),
      ),
      TestHistory(
        id: 'test_003',
        testDate: DateTime.now().subtract(const Duration(days: 90)),
        existenceType: '안정형',
        questionCount: 60,
        duration: const Duration(minutes: 16),
        result: const WpiResult(
          existenceType: '안정형',
          coreMessage: '당신은 안정과 평화를 추구하는 존재 구조를 가지고 있습니다. 변화보다는 익숙한 것을 선호하며, 관계에서 조화를 중시합니다.',
          redLineValue: 0.52,
          redLineDescription: '자기 믿음이 온화한 수준입니다. 타인의 의견을 존중하는 편입니다.',
          blueLineValue: 0.65,
          blueLineDescription: '내면화된 기준이 관계 중심적입니다. 주변과의 조화를 중요시합니다.',
          gapAnalysis: '기준이 자기 믿음보다 약간 높아, 타인을 배려하느라 자신을 돌보지 못할 때가 있습니다.',
          emotionalSignals: ['평온함', '배려심', '소속감', '불안'],
          bodySignals: ['소화 불량', '피로감', '어깨 결림', '안정적 호흡'],
        ),
      ),
    ];
  }
}

