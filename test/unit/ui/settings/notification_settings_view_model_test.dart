import 'package:flutter_test/flutter_test.dart';
import 'package:wpi_app/domain/model/notification_settings.dart';
import 'package:wpi_app/ui/settings/notification_settings_view_model.dart';

import '../../../testing/fakes/fake_notification_repository.dart';

void main() {
  group('NotificationSettingsViewModel', () {
    test('load populates settings', () async {
      final fake = FakeNotificationRepository()
        ..settings = const NotificationSettings(
          notificationsEnabled: false,
          reminderEnabled: true,
          reminderDays: 14,
        );
      final viewModel = NotificationSettingsViewModel(fake);

      await viewModel.load();

      expect(viewModel.loading, isFalse);
      expect(viewModel.notificationsEnabled, isFalse);
      expect(viewModel.reminderEnabled, isTrue);
      expect(viewModel.reminderDays, 14);
    });

    test('setNotificationsEnabled requests permission when enabling', () async {
      final fake = FakeNotificationRepository();
      final viewModel = NotificationSettingsViewModel(fake);

      await viewModel.setNotificationsEnabled(true);

      expect(fake.lastNotificationsEnabled, isTrue);
      expect(fake.requestPermissionCallCount, 1);
      expect(viewModel.notificationsEnabled, isTrue);
    });

    test('setReminder updates repository and state', () async {
      final fake = FakeNotificationRepository();
      final viewModel = NotificationSettingsViewModel(fake);

      await viewModel.setReminderEnabled(false);
      await viewModel.setReminderDays(60);

      expect(fake.lastReminderEnabled, isFalse);
      expect(fake.lastReminderDays, 60);
      expect(viewModel.reminderEnabled, isFalse);
      expect(viewModel.reminderDays, 60);
    });
  });
}
