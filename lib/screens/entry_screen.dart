import 'package:flutter/material.dart';
import '../router/app_routes.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../utils/feature_flags.dart';

class EntryScreen extends StatelessWidget {
  const EntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final signUpEnabled = FeatureFlags.enableEmailSignUp;
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed(AppRoutes.main);
                  },
                  tooltip: '닫기',
                ),
              ),
              const Spacer(flex: 3),
              Text(
                '당신의 이야기를\n구조적으로 정리해요.',
                style: AppTextStyles.h1,
              ),
              const Spacer(flex: 4),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    final ok = await Navigator.of(context, rootNavigator: true).pushNamed<bool>(
                      signUpEnabled ? AppRoutes.signup : AppRoutes.login,
                    );
                    if (ok == true && context.mounted) {
                      Navigator.of(context).pushReplacementNamed(AppRoutes.main);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    signUpEnabled ? '이메일로 회원가입' : '이메일로 로그인',
                    style: AppTextStyles.buttonMedium,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '몇 가지 질문으로 나를 이해하고 성장의 방향을 찾아보세요.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              if (signUpEnabled)
                Center(
                  child: TextButton(
                    onPressed: () async {
                      final ok =
                          await Navigator.of(context, rootNavigator: true).pushNamed<bool>(AppRoutes.login);
                      if (ok == true && context.mounted) {
                        Navigator.of(context).pushReplacementNamed(AppRoutes.main);
                      }
                    },
                    child: Text(
                      '이미 계정이 있으신가요? 로그인',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.secondary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
