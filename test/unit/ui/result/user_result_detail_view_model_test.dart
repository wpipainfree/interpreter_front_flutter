import 'package:flutter_test/flutter_test.dart';
import 'package:wpi_app/domain/model/result_models.dart';
import 'package:wpi_app/ui/result/view_models/user_result_detail_view_model.dart';
import 'package:wpi_app/utils/strings.dart';

import '../../../testing/fakes/fake_result_repository.dart';

void main() {
  group('UserResultDetailViewModel', () {
    test('start loads bundle and initial interpretation when story exists',
        () async {
      final fake = FakeResultRepository()
        ..isLoggedInValue = true
        ..currentUserIdValue = 'user-1'
        ..bundleResult = UserResultDetailBundle(
          reality: _detail(resultId: 10, testId: 1, worry: 'worry'),
          ideal: _detail(resultId: 11, testId: 3),
          mindFocus: 'story',
        );
      final viewModel = UserResultDetailViewModel(
        fake,
        resultId: 10,
      );

      await viewModel.start();
      await Future<void>.delayed(Duration.zero);

      expect(viewModel.loading, isFalse);
      expect(viewModel.error, isNull);
      expect(viewModel.realityDetail?.result.id, 10);
      expect(viewModel.idealDetail?.result.id, 11);
      expect(viewModel.mindFocus, 'story');
      expect(viewModel.initialState, InitialInterpretationLoadState.success);
      expect(viewModel.initialInterpretation, isNotNull);
      expect(viewModel.canOpenPhase3, isTrue);
      expect(viewModel.nextTurn, 2);
    });

    test('start sets login-required error when logged out', () async {
      final fake = FakeResultRepository()
        ..isLoggedInValue = false
        ..currentUserIdValue = null;
      final viewModel = UserResultDetailViewModel(
        fake,
        resultId: 10,
      );

      await viewModel.start();

      expect(viewModel.loading, isFalse);
      expect(viewModel.error, AppStrings.loginRequired);
      expect(viewModel.realityDetail, isNull);
      expect(viewModel.idealDetail, isNull);
      expect(viewModel.initialState, InitialInterpretationLoadState.idle);
    });

    test('submitStory sets error state when ai generation fails', () async {
      final fake = FakeResultRepository()
        ..isLoggedInValue = true
        ..currentUserIdValue = 'user-1'
        ..bundleResult = UserResultDetailBundle(
          reality: _detail(resultId: 10, testId: 1),
          ideal: null,
          mindFocus: null,
        )
        ..initialInterpretationError = Exception('ai failed')
        ..aiErrorMessage = 'friendly ai error';
      final viewModel = UserResultDetailViewModel(
        fake,
        resultId: 10,
      );
      await viewModel.start();

      await viewModel.submitStory('my story');

      expect(viewModel.initialState, InitialInterpretationLoadState.error);
      expect(viewModel.initialError, 'friendly ai error');
      expect(viewModel.mindFocus, 'my story');
    });

    test('auth logout event resets result and interpretation state', () async {
      final fake = FakeResultRepository()
        ..isLoggedInValue = true
        ..currentUserIdValue = 'user-1'
        ..bundleResult = UserResultDetailBundle(
          reality: _detail(resultId: 10, testId: 1),
          ideal: _detail(resultId: 11, testId: 3),
          mindFocus: 'story',
        );
      final viewModel = UserResultDetailViewModel(
        fake,
        resultId: 10,
      );
      await viewModel.start();
      await Future<void>.delayed(Duration.zero);
      expect(viewModel.realityDetail, isNotNull);

      fake
        ..isLoggedInValue = false
        ..currentUserIdValue = null;
      fake.emitAuthChanged();
      await Future<void>.delayed(Duration.zero);

      expect(viewModel.realityDetail, isNull);
      expect(viewModel.idealDetail, isNull);
      expect(viewModel.mindFocus, isNull);
      expect(viewModel.initialState, InitialInterpretationLoadState.idle);
      expect(viewModel.error, AppStrings.loginRequired);
    });
  });
}

UserResultDetail _detail({
  required int resultId,
  required int testId,
  String? worry,
}) {
  return UserResultDetail(
    result: UserResultRow(
      id: resultId,
      userId: 1,
      testId: testId,
      worry: worry,
      createdAt: DateTime(2026, 2, 16, 10, 0),
    ),
    classes: const [
      ResultClassItem(
        id: 1,
        userResultId: 1,
        name: 'Realist',
        checklistName: 'ìžê¸°í‰ê°€',
        point: 60,
      ),
      ResultClassItem(
        id: 2,
        userResultId: 1,
        name: 'Relation',
        checklistName: 'íƒ€ì¸í‰ê°€',
        point: 40,
      ),
    ],
  );
}
