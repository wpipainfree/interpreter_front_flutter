import 'package:flutter_test/flutter_test.dart';
import 'package:wpi_app/domain/model/psych_test_models.dart';
import 'package:wpi_app/domain/usecase/wpi_selection_use_case.dart';

void main() {
  group('WpiSelectionUseCase', () {
    const useCase = WpiSelectionUseCase();

    test('sortChecklistsByRolePriority sorts self -> other -> unknown', () {
      const source = [
        PsychTestChecklist(
          id: 3,
          name: 'Unknown',
          description: '',
          firstCount: 3,
          secondCount: 4,
          thirdCount: 5,
          sequence: 1,
          question: '',
          questions: [],
          role: EvaluationRole.unknown,
        ),
        PsychTestChecklist(
          id: 2,
          name: 'Other',
          description: '',
          firstCount: 3,
          secondCount: 4,
          thirdCount: 5,
          sequence: 1,
          question: '',
          questions: [],
          role: EvaluationRole.other,
        ),
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
          role: EvaluationRole.self,
        ),
      ];

      final sorted = useCase.sortChecklistsByRolePriority(source);

      expect(sorted.map((item) => item.id).toList(), [1, 2, 3]);
    });

    test('resolveInitialIndex prefers requested role when present', () {
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
          role: EvaluationRole.self,
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
          role: EvaluationRole.other,
        ),
      ];

      final initial = useCase.resolveInitialIndex(
        checklists: checklists,
        initialRole: EvaluationRole.other,
      );

      expect(initial, 1);
    });

    test('createSelectionsFromRankMap builds rank buckets', () {
      final selections = useCase.createSelectionsFromRankMap(
        checklistId: 10,
        selectedRanks: const {10: 1, 20: 2, 30: 1, 40: 3},
      );

      expect(selections.checklistId, 10);
      expect(selections.rank1, [10, 30]);
      expect(selections.rank2, [20]);
      expect(selections.rank3, [40]);
    });

    test('createSelectionsFromOrderedIds splits by checklist counts', () {
      const checklist = PsychTestChecklist(
        id: 20,
        name: 'Self',
        description: '',
        firstCount: 2,
        secondCount: 2,
        thirdCount: 1,
        sequence: 1,
        question: '',
        questions: [],
      );

      final selections = useCase.createSelectionsFromOrderedIds(
        checklist: checklist,
        orderedQuestionIds: const [1, 2, 3, 4, 5],
      );

      expect(selections.rank1, [1, 2]);
      expect(selections.rank2, [3, 4]);
      expect(selections.rank3, [5]);
    });

    test('resolveProcessSequence uses stage index when sequence is zero', () {
      const checklist = PsychTestChecklist(
        id: 20,
        name: 'Self',
        description: '',
        firstCount: 2,
        secondCount: 2,
        thirdCount: 1,
        sequence: 0,
        question: '',
        questions: [],
      );

      final sequence = useCase.resolveProcessSequence(
        checklist: checklist,
        stageIndex: 3,
      );

      expect(sequence, 4);
    });

    test('extractResultId supports int/string/map formats', () {
      expect(useCase.extractResultId(1), 1);
      expect(useCase.extractResultId('2'), 2);
      expect(useCase.extractResultId({'result_id': 3}), 3);
      expect(useCase.extractResultId({'RESULT_ID': '4'}), 4);
      expect(useCase.extractResultId({'resultId': '5'}), 5);
      expect(useCase.extractResultId({'other': 6}), isNull);
      expect(useCase.extractResultId(null), isNull);
    });
  });
}
