import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../utils/app_config.dart';
import '../auth/login_screen.dart';
import 'wpi_selection_screen.dart';
import 'wpi_selection_flow_new.dart';

class TestIntroScreen extends StatefulWidget {
  const TestIntroScreen({super.key});

  @override
  State<TestIntroScreen> createState() => _TestIntroScreenState();
}

class _TestIntroScreenState extends State<TestIntroScreen> {
  bool _useNewFlow = AppConfig.useNewWpiFlow;

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
        builder: (_) => _useNewFlow
            ? WpiSelectionFlowNew(testId: testId, testTitle: title)
            : WpiSelectionScreen(testId: testId, testTitle: title),
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '지시문에 맞는 문장을 골라, 지금의 나를 구조로 확인합니다.',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Switch.adaptive(
                    value: _useNewFlow,
                    onChanged: (v) => setState(() => _useNewFlow = v),
                    activeColor: AppColors.secondary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoCard(
                icon: Icons.timer,
                title: '소요 시간',
                content: '약 10–15분',
              ),
              _buildInfoCard(
                icon: Icons.quiz,
                title: '문장 구성',
                content: '나를 표현하는 문장 30개',
              ),
              _buildInfoCard(
                icon: Icons.psychology,
                title: '선택 방법',
                content: '지시문에 맞게 12개 선택 (1순위 3 · 2순위 4 · 3순위 5)',
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
                        '결과는 평가가 아니라 해석을 위한 좌표입니다.',
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
                        '현실 검사 시작',
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
                        '이상 검사 시작',
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
