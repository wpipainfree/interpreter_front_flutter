import 'package:flutter/foundation.dart';

import '../../domain/repository/notification_repository.dart';

class NotificationSettingsViewModel extends ChangeNotifier {
  NotificationSettingsViewModel(this._repository);

  final NotificationRepository _repository;

  bool _notificationsEnabled = true;
  bool _reminderEnabled = true;
  int _reminderDays = 30;
  bool _loading = true;
  String? _error;

  bool get notificationsEnabled => _notificationsEnabled;
  bool get reminderEnabled => _reminderEnabled;
  int get reminderDays => _reminderDays;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> start() => load();

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final settings = await _repository.loadSettings();
      _notificationsEnabled = settings.notificationsEnabled;
      _reminderEnabled = settings.reminderEnabled;
      _reminderDays = settings.reminderDays;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    notifyListeners();

    await _repository.setNotificationsEnabled(enabled);
    if (enabled) {
      await _repository.requestPermission();
    }
  }

  Future<void> setReminderEnabled(bool enabled) async {
    _reminderEnabled = enabled;
    notifyListeners();
    await _repository.setReminderEnabled(enabled);
  }

  Future<void> setReminderDays(int days) async {
    _reminderDays = days;
    notifyListeners();
    await _repository.setReminderDays(days);
  }
}
