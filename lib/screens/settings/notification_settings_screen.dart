import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import '../../utils/app_colors.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  
  bool _notificationsEnabled = true;
  bool _reminderEnabled = true;
  int _reminderDays = 30;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final notificationsEnabled = await _notificationService.isNotificationsEnabled();
    final reminderEnabled = await _notificationService.isReminderEnabled();
    final reminderDays = await _notificationService.getReminderDays();
    
    setState(() {
      _notificationsEnabled = notificationsEnabled;
      _reminderEnabled = reminderEnabled;
      _reminderDays = reminderDays;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('알림 설정'),
        backgroundColor: const Color(0xFF0F4C81),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 안내 텍스트
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F4C81).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.notifications_active_outlined,
                          color: Color(0xFF0F4C81),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '알림을 통해 검사 결과와 리마인더를 받아보세요.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 전체 알림 설정
                  _buildSettingsCard(
                    title: '알림 설정',
                    children: [
                      _buildSwitchTile(
                        icon: Icons.notifications_rounded,
                        iconColor: const Color(0xFF0F4C81),
                        title: '알림 받기',
                        subtitle: '모든 알림을 켜거나 끕니다',
                        value: _notificationsEnabled,
                        onChanged: (value) async {
                          setState(() => _notificationsEnabled = value);
                          await _notificationService.setNotificationsEnabled(value);
                          
                          if (value) {
                            await _notificationService.requestPermission();
                          }
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 검사 완료 알림
                  _buildSettingsCard(
                    title: '검사 완료 알림',
                    enabled: _notificationsEnabled,
                    children: [
                      _buildInfoTile(
                        icon: Icons.check_circle_outline_rounded,
                        iconColor: const Color(0xFF4CAF50),
                        title: '검사 완료 시 알림',
                        subtitle: 'WPI 검사가 완료되면 결과를 알려드립니다',
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 검사 권유 알림
                  _buildSettingsCard(
                    title: '검사 리마인더',
                    enabled: _notificationsEnabled,
                    children: [
                      _buildSwitchTile(
                        icon: Icons.event_repeat_rounded,
                        iconColor: const Color(0xFFF57C00),
                        title: '정기 검사 알림',
                        subtitle: '설정한 기간이 지나면 검사를 권유합니다',
                        value: _reminderEnabled,
                        onChanged: _notificationsEnabled
                            ? (value) async {
                                setState(() => _reminderEnabled = value);
                                await _notificationService.setReminderEnabled(value);
                              }
                            : null,
                      ),
                      if (_reminderEnabled && _notificationsEnabled) ...[
                        const Divider(height: 1),
                        _buildReminderDaysTile(),
                      ],
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 알림 테스트 버튼 (개발용)
                  _buildTestNotificationButton(),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildSettingsCard({
    required String title,
    required List<Widget> children,
    bool enabled = true,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF0F4C81),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '항상 켜짐',
              style: TextStyle(
                fontSize: 12,
                color: iconColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderDaysTile() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              const Text(
                '알림 주기',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                '$_reminderDays일 후',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F4C81),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildDaysChip(7, '7일'),
              const SizedBox(width: 8),
              _buildDaysChip(14, '14일'),
              const SizedBox(width: 8),
              _buildDaysChip(30, '30일'),
              const SizedBox(width: 8),
              _buildDaysChip(60, '60일'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDaysChip(int days, String label) {
    final isSelected = _reminderDays == days;
    return GestureDetector(
      onTap: () async {
        setState(() => _reminderDays = days);
        await _notificationService.setReminderDays(days);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F4C81) : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildTestNotificationButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bug_report_outlined, color: AppColors.textSecondary, size: 20),
              const SizedBox(width: 8),
              Text(
                '테스트 (개발용)',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await _notificationService.showTestCompleteNotification(
                      existenceType: '조화형',
                    );
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('검사 완료 알림이 전송되었습니다')),
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('완료 알림'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4CAF50),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    // 테스트를 위해 10초 후 알림 예약
                    await _notificationService.scheduleTestReminder(daysAfter: 0);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('리마인더가 예약되었습니다 (곧 도착)')),
                    );
                  },
                  icon: const Icon(Icons.schedule, size: 18),
                  label: const Text('리마인더'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFF57C00),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

