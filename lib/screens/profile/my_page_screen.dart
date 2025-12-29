import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../settings/notification_settings_screen.dart';
import '../entry_screen.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser;

    final history = [
      _TestHistory(type: '조화형', date: DateTime.now().subtract(const Duration(days: 2))),
      _TestHistory(type: '도전형', date: DateTime.now().subtract(const Duration(days: 30))),
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        title: Text('마이페이지', style: AppTextStyles.h4),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ProfileHeader(user: user),
            const SizedBox(height: 16),
            _SectionTitle('최근 검사 결과'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: history.map((h) => _HistoryCard(test: h)).toList(growable: false),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 32),
            _SectionTitle('설정'),
            _SettingTile(
              icon: Icons.notifications_outlined,
              title: '알림 설정',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
                );
              },
            ),
            _SettingTile(
              icon: Icons.help_outline,
              title: '도움말',
              onTap: () {},
            ),
            _SettingTile(
              icon: Icons.logout,
              title: '로그아웃',
              isDestructive: true,
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('로그아웃'),
                    content: const Text('정말 로그아웃하시겠어요?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('취소'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('로그아웃', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await authService.logout();
                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const EntryScreen()),
                    (route) => false,
                  );
                }
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final UserInfo? user;
  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    final provider = user?.provider;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.primary.withOpacity(0.12),
            child: Text(
              (user?.nickname ?? 'G')[0].toUpperCase(),
              style: const TextStyle(fontSize: 28, color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?.nickname ?? '게스트', style: AppTextStyles.h4),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '로그인이 필요합니다.',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (provider != null && provider != 'email')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _providerColor(provider),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _providerName(provider),
                style: AppTextStyles.caption.copyWith(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final _TestHistory test;
  const _HistoryCard({required this.test});

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(test.type);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                test.type[0],
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(test.type, style: AppTextStyles.h5),
                const SizedBox(height: 4),
                Text(
                  _formatDate(test.date),
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textHint),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Text(title, style: AppTextStyles.h4),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.red : AppColors.textPrimary;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textHint),
      onTap: onTap,
    );
  }
}

Color _typeColor(String type) {
  switch (type) {
    case '조화형':
      return const Color(0xFF4CAF50);
    case '도전형':
      return const Color(0xFFF57C00);
    case '안정형':
      return const Color(0xFF2196F3);
    case '탐험형':
      return const Color(0xFF9C27B0);
    case '감성형':
      return const Color(0xFFE91E63);
    default:
      return AppColors.secondary;
  }
}

String _formatDate(DateTime date) {
  return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
}

Color _providerColor(String provider) {
  switch (provider) {
    case 'kakao':
      return const Color(0xFFFEE500);
    case 'naver':
      return const Color(0xFF03C75A);
    case 'google':
      return const Color(0xFF4285F4);
    case 'facebook':
      return const Color(0xFF1877F2);
    default:
      return AppColors.textSecondary;
  }
}

String _providerName(String provider) {
  switch (provider) {
    case 'kakao':
      return '카카오';
    case 'naver':
      return '네이버';
    case 'google':
      return 'Google';
    case 'facebook':
      return 'Facebook';
    case 'guest':
      return '게스트';
    default:
      return provider;
  }
}

class _TestHistory {
  final String type;
  final DateTime date;
  const _TestHistory({required this.type, required this.date});
}
