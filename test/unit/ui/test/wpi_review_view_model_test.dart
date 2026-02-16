import 'package:flutter_test/flutter_test.dart';
import 'package:wpi_app/domain/model/psych_test_models.dart';
import 'package:wpi_app/ui/test/wpi_review_view_model.dart';

import '../../../testing/fakes/fake_psych_test_repository.dart';

void main() {
  group('WpiReviewViewModel', () {
    test('submit uses submitResults when existingResultId is null', () async {
      final fake = FakePsychTestRepository()
        ..submitResult = const {'result_id': 101};
      final viewModel = WpiReviewViewModel(fake);
      const selections = WpiSelections(
        checklistId: 10,
        rank1: [1, 2, 3],
        rank2: [4, 5, 6, 7],
        rank3: [8, 9, 10, 11, 12],
      );

      final result = await viewModel.submit(
        testId: 1,
        selections: selections,
        processSequence: 1,
      );

      expect(result['result_id'], 101);
      expect(fake.submitCallCount, 1);
      expect(fake.updateCallCount, 0);
      expect(fake.lastSubmitTestId, 1);
      expect(fake.lastSubmitSelections, same(selections));
      expect(fake.lastSubmitProcessSequence, 1);
      expect(viewModel.submitting, isFalse);
      expect(viewModel.errorMessage, isNull);
    });

    test('submit uses updateResults when existingResultId is present',
        () async {
      final fake = FakePsychTestRepository()
        ..updateResult = const {'result_id': 202};
      final viewModel = WpiReviewViewModel(fake);
      const selections = WpiSelections(
        checklistId: 20,
        rank1: [1, 2, 3],
      );

      final result = await viewModel.submit(
        testId: 2,
        selections: selections,
        processSequence: 2,
        existingResultId: 999,
      );

      expect(result['result_id'], 202);
      expect(fake.submitCallCount, 0);
      expect(fake.updateCallCount, 1);
      expect(fake.lastUpdateResultId, 999);
      expect(fake.lastUpdateSelections, same(selections));
      expect(fake.lastUpdateProcessSequence, 2);
      expect(viewModel.submitting, isFalse);
      expect(viewModel.errorMessage, isNull);
    });

    test('submit stores error message and rethrows on failure', () async {
      final fake = FakePsychTestRepository()..submitError = Exception('boom');
      final viewModel = WpiReviewViewModel(fake);

      await expectLater(
        viewModel.submit(
          testId: 3,
          selections: const WpiSelections(checklistId: 30),
          processSequence: 3,
        ),
        throwsA(isA<Exception>()),
      );
      expect(viewModel.submitting, isFalse);
      expect(viewModel.errorMessage, contains('boom'));
    });
  });
}
