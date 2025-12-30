import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../auth/login_screen.dart';
import 'wpi_selection_screen.dart';

class TestIntroScreen extends StatelessWidget {
  const TestIntroScreen({super.key});

  Future<void> _startTest(BuildContext context, {required int testId, required String title}) async {
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
      MaterialPageRoute(
        builder: (_) => WpiSelectionScreen(testId: testId, testTitle: title),
      ),
    );
  }

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
                content: '총 ${AppConstants.sampleQuestionCount}문항 (맛보기)',
              ),
              _buildInfoCard(
                icon: Icons.psychology,
                title: '검사 목적',
                content: '나의 존재 유형을 빠르게 파악해 다음 여정에 활용합니다.',
              ),
              const Spacer(),
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
                        '결과는 학습을 돕기 위한 참고용입니다. 충분히 휴식한 상태에서 진행해주세요.',
                        style: TextStyle(color: AppColors.gapAnalysisText),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _startTest(context, testId: 1, title: '현실 검사'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: AppColors.textOnPrimary,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '현실 검사',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _startTest(context, testId: 3, title: '이상 검사'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '이상 검사',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
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
