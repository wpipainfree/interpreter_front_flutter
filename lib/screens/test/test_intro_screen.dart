import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../auth/login_screen.dart';
import 'test_screen.dart';

class TestIntroScreen extends StatelessWidget {
  const TestIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'WPI 검사 안내',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              
              _buildInfoCard(
                icon: Icons.timer,
                title: '소요 시간',
                content: '약 1-2분',
              ),
              _buildInfoCard(
                icon: Icons.quiz,
                title: '문항 수',
                content: '총 ${AppConstants.sampleQuestionCount}문항 (샘플)',
              ),
              _buildInfoCard(
                icon: Icons.psychology,
                title: '검사 방법',
                content: '각 문항을 읽고 현재 자신의 상태에 가장 가까운 답변을 선택하세요.',
              ),
              
              const Spacer(),
              
              // 안내 메시지
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.gapAnalysisBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info, color: AppColors.accent),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '정답이 없습니다. 솔직하게 응답해주세요.',
                        style: TextStyle(color: AppColors.gapAnalysisText),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 시작 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final auth = AuthService();
                    if (!auth.isLoggedIn) {
                      final ok = await Navigator.of(context, rootNavigator: true).push<bool>(
                        MaterialPageRoute(
                          fullscreenDialog: true,
                          builder: (_) => const LoginScreen(),
                        ),
                      );
                      if (ok != true || !context.mounted) return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const TestScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: AppColors.textOnPrimary,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '검사 시작',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.secondary),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          content,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
