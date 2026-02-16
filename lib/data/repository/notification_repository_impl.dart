import '../../domain/model/notification_settings.dart';
import '../../domain/repository/notification_repository.dart';
import '../../services/notification_service.dart' as notification;

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl({notification.NotificationService? service})
      : _service = service ?? notification.NotificationService();

  final notification.NotificationService _service;

  @override
  Future<NotificationSettings> loadSettings() async {
    final notificationsEnabled = await _service.isNotificationsEnabled();
    final reminderEnabled = await _service.isReminderEnabled();
    final reminderDays = await _service.getReminderDays();
    return NotificationSettings(
      notificationsEnabled: notificationsEnabled,
      reminderEnabled: reminderEnabled,
      reminderDays: reminderDays,
    );
  }

  @override
  Future<void> setNotificationsEnabled(bool enabled) {
    return _service.setNotificationsEnabled(enabled);
  }

  @override
  Future<void> setReminderEnabled(bool enabled) {
    return _service.setReminderEnabled(enabled);
  }

  @override
  Future<void> setReminderDays(int days) {
    return _service.setReminderDays(days);
  }

  @override
  Future<bool> requestPermission() {
    return _service.requestPermission();
  }
}
