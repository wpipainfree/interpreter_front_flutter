import 'package:flutter_test/flutter_test.dart';
import 'package:wpi_app/domain/model/psych_test_models.dart';
import 'package:wpi_app/domain/model/wpi_flow_state.dart';

void main() {
  group('WpiFlowState', () {
    const checklists = [
      PsychTestChecklist(
        id: 1,
        name: 'Self',
        description: '',
        firstCount: 3,
        secondCount: 4,
        thirdCount: 5,
        sequence: 1,
        question: '',
        questions: [],
      ),
      PsychTestChecklist(
        id: 2,
        name: 'Other',
        description: '',
        firstCount: 3,
        secondCount: 4,
        thirdCount: 5,
        sequence: 2,
        question: '',
        questions: [],
      ),
    ];

    test('currentChecklist and hasNextStage follow stage index', () {
      const state = WpiFlowState(
        checklists: checklists,
        stageIndex: 0,
      );

      expect(state.currentChecklist?.id, 1);
      expect(state.hasNextStage, isTrue);
      expect(
        state.copyWith(stageIndex: 1).currentChecklist?.id,
        2,
      );
      expect(
        state.copyWith(stageIndex: 1).hasNextStage,
        isFalse,
      );
    });

    test('copyWith can clear nullable fields', () {
      const state = WpiFlowState(
        loading: false,
        submitting: true,
        error: 'error',
        resultId: 100,
      );

      final updated = state.copyWith(
        submitting: false,
        error: null,
        resultId: null,
      );

      expect(updated.loading, isFalse);
      expect(updated.submitting, isFalse);
      expect(updated.error, isNull);
      expect(updated.resultId, isNull);
    });
  });
}
