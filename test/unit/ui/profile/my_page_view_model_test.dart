import 'package:flutter_test/flutter_test.dart';
import 'package:wpi_app/domain/model/profile_models.dart';
import 'package:wpi_app/ui/profile/my_page_view_model.dart';

import '../../../testing/fakes/fake_profile_repository.dart';

void main() {
  group('MyPageViewModel', () {
    test('start loads social provider statuses for logged-in user', () async {
      final fake = FakeProfileRepository()
        ..currentUserValue = _user()
        ..providerStatuses = const [
          ProfileSocialProviderStatus(
            provider: 'kakao',
            providerName: '카카오',
            isLinked: true,
          ),
        ];
      final viewModel = MyPageViewModel(fake);

      viewModel.start();
      await _flushAsync();

      expect(viewModel.user?.id, 'user-1');
      expect(viewModel.isProviderLinked('kakao'), isTrue);
      expect(fake.fetchStatusesCallCount, greaterThanOrEqualTo(1));
    });

    test('linkSocialAccount refreshes provider status on success', () async {
      final fake = FakeProfileRepository()
        ..currentUserValue = _user()
        ..providerStatuses = const [];
      final viewModel = MyPageViewModel(fake);
      viewModel.start();
      await _flushAsync();

      fake.providerStatuses = const [
        ProfileSocialProviderStatus(
          provider: 'kakao',
          providerName: '카카오',
          isLinked: true,
        ),
      ];

      final result = await viewModel.linkSocialAccount('kakao');

      expect(result.isSuccess, isTrue);
      expect(fake.linkedProviders, ['kakao']);
      expect(viewModel.isProviderLinked('kakao'), isTrue);
      expect(viewModel.isProviderBusy('kakao'), isFalse);
    });

    test('auth change to logged-out clears user and provider status', () async {
      final fake = FakeProfileRepository()
        ..currentUserValue = _user()
        ..providerStatuses = const [
          ProfileSocialProviderStatus(
            provider: 'google',
            providerName: 'Google',
            isLinked: true,
          ),
        ];
      final viewModel = MyPageViewModel(fake);

      viewModel.start();
      await _flushAsync();

      fake.currentUserValue = null;
      fake.emitAuthChanged();

      expect(viewModel.user, isNull);
      expect(viewModel.socialProviderStatuses, isEmpty);
      expect(viewModel.isProviderLinked('google'), isFalse);
    });

    test('logout delegates to repository', () async {
      final fake = FakeProfileRepository();
      final viewModel = MyPageViewModel(fake);

      await viewModel.logout();

      expect(fake.logoutCallCount, 1);
    });
  });
}

ProfileUser _user() {
  return const ProfileUser(
    id: 'user-1',
    email: 'user@example.com',
    name: 'User',
    provider: 'email',
  );
}

Future<void> _flushAsync() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}
