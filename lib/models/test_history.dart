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

  /// 샘플 데이터
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
          coreMessage: '사람과 관계 속에서 균형을 만들고 조화를 이루는 성향입니다.',
          redLineValue: 0.68,
          redLineDescription: '관계와 협력을 지나치게 의식하면 스스로를 돌보지 못할 수 있어요.',
          blueLineValue: 0.55,
          blueLineDescription: '적절한 경계를 세우며 자신의 필요를 표현해 보세요.',
          gapAnalysis: '균형 잡힌 협업을 위해 명확한 역할과 기대치를 먼저 정하는 것이 도움이 됩니다.',
          emotionalSignals: ['기대 충족 압박', '눈치 보기', '피로감', '소진감'],
          bodySignals: ['어깨 결림', '호흡이 짧아짐', '두통', '가슴 답답함'],
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
          coreMessage: '높은 목표를 세우고 추진하는 힘이 강합니다.',
          redLineValue: 0.82,
          redLineDescription: '과도한 몰입은 번아웃을 불러올 수 있습니다.',
          blueLineValue: 0.45,
          blueLineDescription: '휴식과 지원을 계획적으로 챙기면 지속력이 높아집니다.',
          gapAnalysis: '목표를 단계로 나누고, 진행 상황을 주기적으로 점검해 보세요.',
          emotionalSignals: ['조급함', '초조함', '짜증', '예민함'],
          bodySignals: ['턱 힘주기', '호흡 가빠짐', '어깨 뭉침', '소화 불량'],
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
          coreMessage: '안정과 일관성을 중시하며 신뢰를 쌓는 스타일입니다.',
          redLineValue: 0.52,
          redLineDescription: '변화를 지나치게 피하면 기회를 놓칠 수 있습니다.',
          blueLineValue: 0.65,
          blueLineDescription: '작은 변화부터 시도하며 안전망을 마련하세요.',
          gapAnalysis: '익숙한 틀 안에서도 새로운 시도를 한 가지씩 추가해 보세요.',
          emotionalSignals: ['걱정', '망설임', '피로', '무기력'],
          bodySignals: ['목·어깨 뻐근함', '수면 질 저하', '복부 긴장', '두통'],
        ),
      ),
    ];
  }
}
