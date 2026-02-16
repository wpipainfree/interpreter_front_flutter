import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/di/app_scope.dart';
import '../../router/app_routes.dart';
import '../../ui/auth/view_models/login_view_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../utils/feature_flags.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final LoginViewModel _viewModel =
      LoginViewModel(AppScope.instance.authRepository);

  bool _isLoading = false;
  String? _errorMessage;
  String? _debugMessage;

  Future<void> _handleSocialLogin(String provider) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _debugMessage = null;
    });

    final result = await _viewModel.loginWithSocial(provider);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.action == LoginAction.success) {
      _completeAuth(success: true);
      return;
    }

    if (result.action == LoginAction.signupRequired) {
      Navigator.of(context, rootNavigator: true)
          .pushReplacementNamed(AppRoutes.signup);
      return;
    }

    final failure = result.failure;
    setState(() {
      _errorMessage = failure?.userMessage;
      _debugMessage = failure?.debugMessage;
    });
  }

  Future<void> _handleGuestLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _debugMessage = null;
    });

    final result = await _viewModel.loginAsGuest();
    if (!mounted) return;

    setState(() => _isLoading = false);
    if (result.action == LoginAction.success) {
      _completeAuth(success: true);
      return;
    }

    final failure = result.failure;
    setState(() {
      _errorMessage = failure?.userMessage ?? '게스트 로그인에 실패했습니다.';
      _debugMessage = failure?.debugMessage;
    });
  }

  Future<void> _openEmailLogin() async {
    await Navigator.of(context, rootNavigator: true)
        .pushNamed<bool>(AppRoutes.loginEmail);
  }

  void _completeAuth({required bool success}) {
    if (success) {
      Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
        AppRoutes.main,
        (route) => false,
      );
      return;
    }

    Navigator.of(context, rootNavigator: true).pop(success);
  }

  @override
  Widget build(BuildContext context) {
    const socialEnabled = FeatureFlags.enableSocialLogin;
    const signUpEnabled = FeatureFlags.enableEmailSignUp;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _completeAuth(success: false);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundLight,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _completeAuth(success: false),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _LoginHeader(),
                const SizedBox(height: 28),
                if (socialEnabled) ...[
                  _SocialButton(
                    label: '카카오로 계속하기',
                    backgroundColor: AppColors.kakao,
                    textColor: AppColors.kakaoText,
                    icon: Icons.chat_bubble_outline_rounded,
                    onPressed:
                        _isLoading ? null : () => _handleSocialLogin('kakao'),
                  ),
                  const SizedBox(height: 12),
                  _SocialButton(
                    label: 'Google로 계속하기',
                    backgroundColor: Colors.white,
                    textColor: AppColors.textPrimary,
                    icon: Icons.public,
                    borderColor: AppColors.border,
                    onPressed:
                        _isLoading ? null : () => _handleSocialLogin('google'),
                  ),
                  if (!kIsWeb && Platform.isIOS) ...[
                    const SizedBox(height: 12),
                    _SocialButton(
                      label: 'Apple로 계속하기',
                      backgroundColor: Colors.black,
                      textColor: Colors.white,
                      icon: Icons.apple,
                      onPressed:
                          _isLoading ? null : () => _handleSocialLogin('apple'),
                    ),
                  ],
                ] else
                  const _SocialDisabledNotice(),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  _ErrorBanner(
                    message: _errorMessage!,
                    debugMessage: kDebugMode ? _debugMessage : null,
                  ),
                ],
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _openEmailLogin,
                    icon: const Icon(Icons.email_outlined),
                    label: Text(
                      '이메일로 로그인',
                      style: AppTextStyles.buttonMedium
                          .copyWith(color: AppColors.textPrimary),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: BorderSide(
                        color: AppColors.border.withValues(
                          alpha: _isLoading ? 0.5 : 1,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (signUpEnabled) ...[
                  Center(
                    child: TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.of(context, rootNavigator: true)
                                  .pushReplacementNamed(AppRoutes.signup);
                            },
                      child: Text(
                        '아직 계정이 없으신가요? 회원가입',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.secondary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Center(
                  child: TextButton(
                    onPressed: _isLoading ? null : _handleGuestLogin,
                    child: Text(
                      '로그인 없이 둘러보기',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '로그인',
          style: AppTextStyles.h2,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '소셜 로그인으로 빠르게 시작해보세요.',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _SocialDisabledNotice extends StatelessWidget {
  const _SocialDisabledNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        '현재 소셜 로그인이 비활성화되어 있어 이메일 로그인을 사용해주세요.',
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;
  final Color? borderColor;
  final VoidCallback? onPressed;

  const _SocialButton({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
    this.borderColor,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;
    final effectiveTextColor =
        isEnabled ? textColor : textColor.withValues(alpha: 0.7);

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          disabledBackgroundColor: backgroundColor.withValues(alpha: 0.45),
          disabledForegroundColor: textColor.withValues(alpha: 0.7),
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: borderColor != null
                ? BorderSide(
                    color: borderColor!.withValues(alpha: isEnabled ? 1 : 0.4),
                  )
                : BorderSide.none,
          ),
        ),
        icon: Icon(icon, size: 20, color: effectiveTextColor),
        label: Text(
          label,
          style: AppTextStyles.buttonMedium.copyWith(
            color: effectiveTextColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final String? debugMessage;

  const _ErrorBanner({required this.message, this.debugMessage});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: Colors.red.shade700),
                ),
                if (debugMessage != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    debugMessage!,
                    style: AppTextStyles.caption
                        .copyWith(color: Colors.red.shade700),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
