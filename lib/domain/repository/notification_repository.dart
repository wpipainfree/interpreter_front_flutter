import '../model/notification_settings.dart';

abstract interface class NotificationRepository {
  Future<NotificationSettings> loadSettings();

  Future<void> setNotificationsEnabled(bool enabled);

  Future<void> setReminderEnabled(bool enabled);

  Future<void> setReminderDays(int days);

  Future<bool> requestPermission();
}
