import 'package:flutter_test/flutter_test.dart';
import 'package:wpi_app/ui/main/main_shell_view_model.dart';

import '../../../testing/fakes/fake_profile_repository.dart';

void main() {
  group('MainShellViewModel', () {
    test('reflects initial login state and auth updates', () {
      final fake = FakeProfileRepository()..isLoggedInValue = false;
      final viewModel = MainShellViewModel(fake);

      expect(viewModel.isLoggedIn, isFalse);

      viewModel.start();
      fake.isLoggedInValue = true;
      fake.emitAuthChanged();

      expect(viewModel.isLoggedIn, isTrue);
    });

    test('refreshAuthState reads latest state from repository', () {
      final fake = FakeProfileRepository()..isLoggedInValue = false;
      final viewModel = MainShellViewModel(fake);

      viewModel.start();
      fake.isLoggedInValue = true;
      viewModel.refreshAuthState();

      expect(viewModel.isLoggedIn, isTrue);
    });
  });
}
