import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../settings/notification_settings_screen.dart';
import '../entry_screen.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser;
    
    final testHistory = [
      _TestHistory(type: '조화형', date: DateTime.now().subtract(const Duration(days: 2))),
      _TestHistory(type: '도전형', date: DateTime.now().subtract(const Duration(days: 30))),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('마이페이지'),
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 프로필 섹션
            Container(
              padding: const EdgeInsets.all(24),
              color: const Color(0xFFE0F2F1),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: const Color(0xFF00897B),
                    child: Text(
                      (user?.nickname ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(fontSize: 32, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.nickname ?? '사용자',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? '',
                          style: const TextStyle(color: Color(0xFF666666)),
                        ),
                        if (user?.provider != null && user!.provider != 'email') ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getProviderColor(user.provider),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getProviderName(user.provider),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // 검사 이력 섹션
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '검사 이력',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ...testHistory.map(
                    (test) => Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _typeColor(test.type),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              test.type[0],
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          '${test.type} 유형',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(_formatDate(test.date)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {},
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const Divider(),
            
            // 설정 메뉴
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('프로필 수정'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // TODO: 프로필 수정 화면
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('알림 설정'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('도움말'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // TODO: 도움말 화면
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('로그아웃', style: TextStyle(color: Colors.red)),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('로그아웃'),
                    content: const Text('정말 로그아웃 하시겠습니까?'),
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
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case '조화형':
        return const Color(0xFF4CAF50);
      case '도전형':
        return const Color(0xFFF57C00);
      default:
        return const Color(0xFF0288D1);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  Color _getProviderColor(String provider) {
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
        return const Color(0xFF666666);
    }
  }

  String _getProviderName(String provider) {
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
}

class _TestHistory {
  final String type;
  final DateTime date;
  const _TestHistory({required this.type, required this.date});
}
