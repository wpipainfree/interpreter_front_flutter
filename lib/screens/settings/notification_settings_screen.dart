import 'package:flutter/material.dart';

import '../../app/di/app_scope.dart';
import '../../ui/settings/notification_settings_view_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  late final NotificationSettingsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = NotificationSettingsViewModel(
      AppScope.instance.notificationRepository,
    );
    _viewModel.addListener(_handleViewModelChanged);
    _viewModel.start();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_handleViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _handleViewModelChanged() {
    if (!mounted) return;
    setState(() {});
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
      body: _viewModel.loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F4C81).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.notifications_active_outlined,
                          color: Color(0xFF0F4C81),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '??? ?? ?? ??? ????? ?????.',
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
                  _buildSettingsCard(
                    title: '알림 설정',
                    children: [
                      _buildSwitchTile(
                        icon: Icons.notifications_rounded,
                        iconColor: const Color(0xFF0F4C81),
                        title: '알림 받기',
                        subtitle: '모든 알림을 켜거나 끕니다',
                        value: _viewModel.notificationsEnabled,
                        onChanged: _viewModel.setNotificationsEnabled,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSettingsCard(
                    title: '검사 완료 알림',
                    enabled: _viewModel.notificationsEnabled,
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
                  _buildSettingsCard(
                    title: '검사 리마인더',
                    enabled: _viewModel.notificationsEnabled,
                    children: [
                      _buildSwitchTile(
                        icon: Icons.event_repeat_rounded,
                        iconColor: const Color(0xFFF57C00),
                        title: '정기 검사 알림',
                        subtitle: '설정한 기간이 지나면 검사를 권유합니다',
                        value: _viewModel.reminderEnabled,
                        onChanged: _viewModel.notificationsEnabled
                            ? _viewModel.setReminderEnabled
                            : null,
                      ),
                      if (_viewModel.reminderEnabled &&
                          _viewModel.notificationsEnabled) ...[
                        const Divider(height: 1),
                        _buildReminderDaysTile(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
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
              color: Colors.black.withValues(alpha: 0.04),
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
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
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
              color: iconColor.withValues(alpha: 0.1),
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
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF0F4C81),
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
              color: iconColor.withValues(alpha: 0.1),
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
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '항상 켜짐',
              style: AppTextStyles.captionSmall.copyWith(
                color: iconColor,
                fontWeight: FontWeight.w700,
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
              const Icon(
                Icons.schedule,
                size: 20,
                color: AppColors.textSecondary,
              ),
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
                '${_viewModel.reminderDays}일 후',
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
    final isSelected = _viewModel.reminderDays == days;
    return GestureDetector(
      onTap: () => _viewModel.setReminderDays(days),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F4C81) : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTextStyles.captionSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
