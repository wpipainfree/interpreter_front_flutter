import 'package:flutter_test/flutter_test.dart';
import 'package:wpi_app/ui/result/view_models/user_result_single_view_model.dart';
import 'package:wpi_app/utils/strings.dart';

import '../../../testing/fakes/fake_result_repository.dart';

void main() {
  group('UserResultSingleViewModel', () {
    test('start loads result detail when logged in', () async {
      final fake = FakeResultRepository()
        ..isLoggedInValue = true
        ..currentUserIdValue = 'user-1';
      final viewModel = UserResultSingleViewModel(
        fake,
        resultId: 10,
      );

      await viewModel.start();

      expect(viewModel.loading, isFalse);
      expect(viewModel.error, isNull);
      expect(viewModel.detail, isNotNull);
    });

    test('start sets login-required error when logged out', () async {
      final fake = FakeResultRepository()
        ..isLoggedInValue = false
        ..currentUserIdValue = null;
      final viewModel = UserResultSingleViewModel(
        fake,
        resultId: 10,
      );

      await viewModel.start();

      expect(viewModel.loading, isFalse);
      expect(viewModel.detail, isNull);
      expect(viewModel.error, AppStrings.loginRequired);
    });

    test('auth logout event clears detail and sets login-required error',
        () async {
      final fake = FakeResultRepository()
        ..isLoggedInValue = true
        ..currentUserIdValue = 'user-1';
      final viewModel = UserResultSingleViewModel(
        fake,
        resultId: 10,
      );
      await viewModel.start();
      expect(viewModel.detail, isNotNull);

      fake
        ..isLoggedInValue = false
        ..currentUserIdValue = null;
      fake.emitAuthChanged();
      await Future<void>.delayed(Duration.zero);

      expect(viewModel.detail, isNull);
      expect(viewModel.error, AppStrings.loginRequired);
    });

    test('load sets error when repository throws', () async {
      final fake = FakeResultRepository()
        ..isLoggedInValue = true
        ..currentUserIdValue = 'user-1'
        ..detailError = Exception('boom');
      final viewModel = UserResultSingleViewModel(
        fake,
        resultId: 10,
      );

      await viewModel.load();

      expect(viewModel.loading, isFalse);
      expect(viewModel.error, contains('boom'));
    });
  });
}
