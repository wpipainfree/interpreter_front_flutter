import 'package:flutter_test/flutter_test.dart';
import 'package:wpi_app/domain/model/psych_test_models.dart';
import 'package:wpi_app/ui/test/wpi_selection_flow_view_model.dart';

import '../../../testing/fakes/fake_psych_test_repository.dart';

void main() {
  group('WpiSelectionFlowViewModel', () {
    test('loadChecklists sorts by role priority (self, other, unknown)',
        () async {
      final fake = FakePsychTestRepository()
        ..checklistsResult = const [
          PsychTestChecklist(
            id: 3,
            name: 'Unknown',
            description: '',
            firstCount: 3,
            secondCount: 4,
            thirdCount: 5,
            sequence: 3,
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
            sequence: 2,
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
      final viewModel = WpiSelectionFlowViewModel(fake);

      final sorted = await viewModel.loadChecklists(99);

      expect(sorted.map((item) => item.id).toList(), [1, 2, 3]);
      expect(fake.fetchChecklistsCallCount, 1);
      expect(fake.lastFetchTestId, 99);
    });

    test('resolveInitialIndex returns role index when present', () {
      final viewModel = WpiSelectionFlowViewModel(FakePsychTestRepository());
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

      final index = viewModel.resolveInitialIndex(
        checklists: checklists,
        initialRole: EvaluationRole.other,
      );

      expect(index, 1);
    });

    test('createSelectionsFromOrderedIds splits ids by checklist counts', () {
      final viewModel = WpiSelectionFlowViewModel(FakePsychTestRepository());
      const checklist = PsychTestChecklist(
        id: 10,
        name: 'Self',
        description: '',
        firstCount: 2,
        secondCount: 2,
        thirdCount: 1,
        sequence: 1,
        question: '',
        questions: [],
      );

      final selections = viewModel.createSelectionsFromOrderedIds(
        checklist: checklist,
        orderedQuestionIds: const [1, 2, 3, 4, 5],
      );

      expect(selections.rank1, [1, 2]);
      expect(selections.rank2, [3, 4]);
      expect(selections.rank3, [5]);
    });

    test('resolveProcessSequence uses stage index when sequence is zero', () {
      final viewModel = WpiSelectionFlowViewModel(FakePsychTestRepository());
      const checklist = PsychTestChecklist(
        id: 10,
        name: 'Self',
        description: '',
        firstCount: 3,
        secondCount: 4,
        thirdCount: 5,
        sequence: 0,
        question: '',
        questions: [],
      );

      final sequence = viewModel.resolveProcessSequence(
        checklist: checklist,
        stageIndex: 1,
      );

      expect(sequence, 2);
    });

    test('submitSelection uses submitResults when resultId is null', () async {
      final fake = FakePsychTestRepository()
        ..submitResult = const {'result_id': 111};
      final viewModel = WpiSelectionFlowViewModel(fake);
      const selections = WpiSelections(checklistId: 10, rank1: [1, 2, 3]);

      final result = await viewModel.submitSelection(
        testId: 1,
        selections: selections,
        processSequence: 1,
        mindFocus: 'stress',
      );

      expect(result['result_id'], 111);
      expect(fake.submitCallCount, 1);
      expect(fake.updateCallCount, 0);
      expect(fake.lastSubmitWorry, 'stress');
      expect(fake.lastSubmitProcessSequence, 1);
    });

    test('submitSelection uses updateResults when resultId is present',
        () async {
      final fake = FakePsychTestRepository()
        ..updateResult = const {'result_id': 222};
      final viewModel = WpiSelectionFlowViewModel(fake);
      const selections = WpiSelections(checklistId: 20, rank1: [4, 5, 6]);

      final result = await viewModel.submitSelection(
        testId: 2,
        selections: selections,
        processSequence: 2,
        resultId: 500,
      );

      expect(result['result_id'], 222);
      expect(fake.submitCallCount, 0);
      expect(fake.updateCallCount, 1);
      expect(fake.lastUpdateResultId, 500);
      expect(fake.lastUpdateProcessSequence, 2);
    });

    test('extractResultId supports int/string/map formats', () {
      final viewModel = WpiSelectionFlowViewModel(FakePsychTestRepository());

      expect(viewModel.extractResultId(1), 1);
      expect(viewModel.extractResultId('2'), 2);
      expect(viewModel.extractResultId({'result_id': 3}), 3);
      expect(viewModel.extractResultId({'RESULT_ID': '4'}), 4);
      expect(viewModel.extractResultId({'resultId': '5'}), 5);
      expect(viewModel.extractResultId({'x': 1}), isNull);
      expect(viewModel.extractResultId(null), isNull);
    });
  });
}
