class NotificationSettings {
  const NotificationSettings({
    required this.notificationsEnabled,
    required this.reminderEnabled,
    required this.reminderDays,
  });

  final bool notificationsEnabled;
  final bool reminderEnabled;
  final int reminderDays;
}
