import 'package:wpi_app/domain/model/notification_settings.dart';
import 'package:wpi_app/domain/repository/notification_repository.dart';

class FakeNotificationRepository implements NotificationRepository {
  NotificationSettings settings = const NotificationSettings(
    notificationsEnabled: true,
    reminderEnabled: true,
    reminderDays: 30,
  );
  bool permissionResult = true;
  Object? loadError;

  bool? lastNotificationsEnabled;
  bool? lastReminderEnabled;
  int? lastReminderDays;
  int requestPermissionCallCount = 0;

  @override
  Future<NotificationSettings> loadSettings() async {
    if (loadError != null) throw loadError!;
    return settings;
  }

  @override
  Future<void> setNotificationsEnabled(bool enabled) async {
    lastNotificationsEnabled = enabled;
  }

  @override
  Future<void> setReminderEnabled(bool enabled) async {
    lastReminderEnabled = enabled;
  }

  @override
  Future<void> setReminderDays(int days) async {
    lastReminderDays = days;
  }

  @override
  Future<bool> requestPermission() async {
    requestPermissionCallCount += 1;
    return permissionResult;
  }
}
