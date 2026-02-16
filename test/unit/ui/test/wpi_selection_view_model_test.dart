import 'package:flutter_test/flutter_test.dart';
import 'package:wpi_app/domain/model/psych_test_models.dart';
import 'package:wpi_app/ui/test/wpi_selection_view_model.dart';

import '../../../testing/fakes/fake_psych_test_repository.dart';

void main() {
  group('WpiSelectionViewModel', () {
    test('loadChecklists returns checklist list from repository', () async {
      final fake = FakePsychTestRepository()
        ..checklistsResult = const [
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
        ];
      final viewModel = WpiSelectionViewModel(fake);

      final lists = await viewModel.loadChecklists(10);

      expect(lists.length, 1);
      expect(lists.first.id, 1);
      expect(fake.fetchChecklistsCallCount, 1);
      expect(fake.lastFetchTestId, 10);
    });

    test('loadChecklists throws when repository returns empty list', () async {
      final viewModel = WpiSelectionViewModel(FakePsychTestRepository());

      await expectLater(
        viewModel.loadChecklists(10),
        throwsA(isA<PsychTestException>()),
      );
    });

    test('createSelections maps selected ranks into rank buckets', () {
      final viewModel = WpiSelectionViewModel(FakePsychTestRepository());
      final selectedRanks = <int, int>{
        100: 2,
        200: 1,
        300: 3,
        400: 1,
      };

      final selections = viewModel.createSelections(
        checklistId: 99,
        selectedRanks: selectedRanks,
      );

      expect(selections.checklistId, 99);
      expect(selections.rank1, [200, 400]);
      expect(selections.rank2, [100]);
      expect(selections.rank3, [300]);
    });

    test('resolveProcessSequence uses stage index when sequence is zero', () {
      final viewModel = WpiSelectionViewModel(FakePsychTestRepository());
      const checklist = PsychTestChecklist(
        id: 1,
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
        stageIndex: 2,
      );

      expect(sequence, 3);
    });

    test('extractResultId supports int/string/map formats', () {
      final viewModel = WpiSelectionViewModel(FakePsychTestRepository());

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
