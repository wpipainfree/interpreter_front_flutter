import 'package:flutter_test/flutter_test.dart';
import 'package:wpi_app/models/initial_interpretation_v1.dart';
import 'package:wpi_app/models/openai_interpret_response.dart';

void main() {
  test('parses cards_v1 view_model and orders cards by fixed ids', () {
    final json = <String, dynamic>{
      'session': {'session_id': 'sess_123', 'turn': 1},
      'interpretation': {
        'title': '초기 해석',
        'response': 'fallback markdown',
        'view_model': {
          'headline': '지금의 나는 연결되고 싶음과 실수하면 안 됨이 충돌합니다.',
          'cards': [
            {
              'id': 'belief',
              'title': '믿음',
              'summary': '핵심 믿음 요약',
              'bullets': ['bullet A', 'bullet B'],
              'check_question': '이 믿음이 사실인지 확인해볼까요?',
            },
            {
              'id': 'story_link',
              'title': '사연 연결',
              'summary': '사연과 구조 연결',
              'bullets': [],
            },
            {
              'id': 'standard',
              'title': '기준',
              'summary': '기준 요약',
            },
            {
              'id': 'emotion_body',
              'title': '감정/몸',
              'summary': '감정과 몸 반응',
            },
            {
              'id': 'direction',
              'title': '방향',
              'summary': '다음 방향',
            },
          ],
          'next': {'cta_label': '내 마음 더 알아보기', 'action': 'phase3'},
          'suggested_prompts': [
            '지금 마음 한 문장',
            '가장 큰 충돌은?',
            '오늘 할 수 있는 다음 선택 1개',
          ],
        },
      },
    };

    final parsed = OpenAIInterpretResponse.fromJson(json);
    expect(parsed.session?.sessionId, 'sess_123');
    expect(parsed.session?.turn, 1);

    final vm = parsed.interpretation?.viewModel;
    expect(vm, isNotNull);
    expect(vm!.headline, isNotEmpty);
    expect(vm.suggestedPrompts, hasLength(3));
    expect(
      vm.cards.map((e) => e.id).toList(),
      InitialInterpretationV1.orderedCardIds,
    );
    expect(vm.cards.first.title, '사연 연결');
    expect(vm.cards[2].id, 'belief');
    expect(vm.cards[2].bullets, ['bullet A', 'bullet B']);
    expect(vm.cards[2].checkQuestion, isNotNull);
  });

  test('falls back when view_model missing', () {
    final json = <String, dynamic>{
      'session': {'session_id': 'sess_999', 'turn': 2},
      'interpretation': {
        'title': '초기 해석',
        'response': '## 제목\n본문',
      },
    };

    final parsed = OpenAIInterpretResponse.fromJson(json);
    expect(parsed.session?.sessionId, 'sess_999');
    expect(parsed.interpretation?.viewModel, isNull);
    expect(parsed.interpretation?.viewModelMalformed, isFalse);
    expect(parsed.interpretation?.response, '## 제목\n본문');
  });

  test('marks view_model malformed when non-map', () {
    final json = <String, dynamic>{
      'session': {'session_id': 'sess_bad', 'turn': 1},
      'interpretation': {
        'title': '초기 해석',
        'response': 'fallback',
        'view_model': 'not-a-map',
      },
    };

    final parsed = OpenAIInterpretResponse.fromJson(json);
    expect(parsed.interpretation?.viewModel, isNull);
    expect(parsed.interpretation?.viewModelMalformed, isTrue);
  });
}

