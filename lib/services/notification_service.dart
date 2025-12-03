import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';

/// WPI 알림 서비스
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  // 알림 채널 ID
  static const String _testCompleteChannelId = 'wpi_test_complete';
  static const String _testReminderChannelId = 'wpi_test_reminder';
  
  // 알림 ID
  static const int _testCompleteNotificationId = 1;
  static const int _testReminderNotificationId = 2;
  
  // SharedPreferences 키
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyReminderEnabled = 'reminder_enabled';
  static const String _keyLastTestDate = 'last_test_date';
  static const String _keyReminderDays = 'reminder_days';

  /// 알림 서비스 초기화
  Future<void> initialize() async {
    // 시간대 초기화
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    // Android 설정
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS 설정
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // 초기화
    await _notifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Android 알림 채널 생성
    await _createNotificationChannels();
    
    // 검사 권유 알림 스케줄 확인
    await _checkAndScheduleReminder();
  }

  /// 알림 채널 생성 (Android)
  Future<void> _createNotificationChannels() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      // 검사 완료 채널
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _testCompleteChannelId,
          '검사 완료 알림',
          description: 'WPI 검사 완료 시 알림',
          importance: Importance.high,
        ),
      );
      
      // 검사 리마인더 채널
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _testReminderChannelId,
          '검사 리마인더',
          description: 'WPI 검사 권유 알림',
          importance: Importance.defaultImportance,
        ),
      );
    }
  }

  /// 알림 탭 처리
  void _onNotificationTap(NotificationResponse response) {
    debugPrint('알림 클릭: ${response.payload}');
    // TODO: 알림 클릭 시 해당 화면으로 이동
  }

  /// 알림 권한 요청
  Future<bool> requestPermission() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }
    
    // iOS는 초기화 시 자동으로 권한 요청
    return true;
  }

  // ============================================
  // 1. 검사 완료 알림
  // ============================================

  /// 검사 완료 알림 표시
  Future<void> showTestCompleteNotification({
    required String existenceType,
  }) async {
    final enabled = await isNotificationsEnabled();
    if (!enabled) return;

    await _notifications.show(
      _testCompleteNotificationId,
      '검사가 완료되었습니다! 🎉',
      '당신의 존재 유형은 "$existenceType"입니다. 결과를 확인해보세요.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _testCompleteChannelId,
          '검사 완료 알림',
          channelDescription: 'WPI 검사 완료 시 알림',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF0F4C81),
          styleInformation: const BigTextStyleInformation(
            '검사 결과가 준비되었습니다. 앱을 열어 상세한 분석 결과를 확인해보세요.',
          ),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'test_complete',
    );

    // 마지막 검사 날짜 저장 및 리마인더 재설정
    await _saveLastTestDate();
    await scheduleTestReminder();
  }

  // ============================================
  // 2. 검사 권유 알림 (30일 후)
  // ============================================

  /// 검사 권유 알림 예약
  Future<void> scheduleTestReminder({int? daysAfter}) async {
    final enabled = await isReminderEnabled();
    if (!enabled) return;

    // 기존 알림 취소
    await _notifications.cancel(_testReminderNotificationId);

    final days = daysAfter ?? await getReminderDays();
    final scheduledDate = tz.TZDateTime.now(tz.local).add(Duration(days: days));

    await _notifications.zonedSchedule(
      _testReminderNotificationId,
      '마음 상태를 확인해볼까요? 💙',
      '마지막 검사 후 $days일이 지났어요. 지금의 마음 상태를 확인해보세요.',
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _testReminderChannelId,
          '검사 리마인더',
          channelDescription: 'WPI 검사 권유 알림',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF2E7D32),
          styleInformation: const BigTextStyleInformation(
            '정기적인 마음 체크는 자기 이해에 도움이 됩니다. WPI 검사로 현재 상태를 확인해보세요.',
          ),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'test_reminder',
    );

    debugPrint('검사 권유 알림 예약: ${scheduledDate.toString()}');
  }

  /// 검사 권유 알림 취소
  Future<void> cancelTestReminder() async {
    await _notifications.cancel(_testReminderNotificationId);
  }

  /// 리마인더 스케줄 확인 및 재설정
  Future<void> _checkAndScheduleReminder() async {
    final lastTestDate = await getLastTestDate();
    if (lastTestDate == null) return;

    final daysSinceLastTest = DateTime.now().difference(lastTestDate).inDays;
    final reminderDays = await getReminderDays();

    if (daysSinceLastTest < reminderDays) {
      // 아직 리마인더 날짜가 안 됐으면 남은 일수로 예약
      final remainingDays = reminderDays - daysSinceLastTest;
      await scheduleTestReminder(daysAfter: remainingDays);
    }
  }

  // ============================================
  // 설정 관리
  // ============================================

  /// 알림 활성화 여부 확인
  Future<bool> isNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotificationsEnabled) ?? true;
  }

  /// 알림 활성화 설정
  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationsEnabled, enabled);
  }

  /// 리마인더 활성화 여부 확인
  Future<bool> isReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyReminderEnabled) ?? true;
  }

  /// 리마인더 활성화 설정
  Future<void> setReminderEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyReminderEnabled, enabled);
    
    if (enabled) {
      await scheduleTestReminder();
    } else {
      await cancelTestReminder();
    }
  }

  /// 리마인더 일수 가져오기 (기본 30일)
  Future<int> getReminderDays() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyReminderDays) ?? 30;
  }

  /// 리마인더 일수 설정
  Future<void> setReminderDays(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyReminderDays, days);
    await scheduleTestReminder(daysAfter: days);
  }

  /// 마지막 검사 날짜 저장
  Future<void> _saveLastTestDate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastTestDate, DateTime.now().toIso8601String());
  }

  /// 마지막 검사 날짜 가져오기
  Future<DateTime?> getLastTestDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString(_keyLastTestDate);
    if (dateStr == null) return null;
    return DateTime.tryParse(dateStr);
  }

  /// 모든 알림 취소
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// 예약된 알림 목록 확인 (디버깅용)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}

