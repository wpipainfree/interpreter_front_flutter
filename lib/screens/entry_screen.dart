import 'package:flutter/material.dart';
import 'auth/login_screen.dart';
import 'auth/signup_screen.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import 'main_shell.dart';

class EntryScreen extends StatelessWidget {
  const EntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    final ok = await Navigator.of(context, rootNavigator: true).push<bool>(
                      MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (_) => const SignUpScreen(),
                      ),
                    );
                    if (ok == true && context.mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const MainShell()),
                      );
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
                    '이메일로 회원가입',
                    style: AppTextStyles.buttonMedium,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '몇 가지 질문으로 나를 이해하고 성장의 방향을 찾아보세요.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textHint,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () async {
                    final ok = await Navigator.of(context, rootNavigator: true).push<bool>(
                      MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (_) => const LoginScreen(),
                      ),
                    );
                    if (ok == true && context.mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const MainShell()),
                      );
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
