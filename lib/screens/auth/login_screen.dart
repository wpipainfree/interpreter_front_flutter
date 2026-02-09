import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../router/app_routes.dart';
import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../utils/feature_flags.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String? _debugMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSocialLogin(String provider) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _debugMessage = null;
    });

    final result = await _authService.loginWithSocial(provider);

    setState(() => _isLoading = false);

    if (result.isSuccess) {
      _completeAuth(success: true);
      return;
    }

    // 미등록 사용자인 경우 회원가입 페이지로 이동
    if (result.isUserNotRegistered) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true)
          .pushReplacementNamed(AppRoutes.signup);
      return;
    }

    setState(() {
      _errorMessage = result.errorMessage;
      _debugMessage = result.debugMessage;
    });
  }

  Future<void> _handleEmailLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _debugMessage = null;
    });

    final result = await _authService.loginWithEmail(
      _emailController.text.trim(),
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (result.isSuccess) {
      _completeAuth(success: true);
      return;
    }
    setState(() {
      _errorMessage = result.errorMessage;
      _debugMessage = result.debugMessage;
    });
  }

  Future<void> _handleGuestLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _debugMessage = null;
    });
    await _authService.loginAsGuest();
    if (!mounted) return;
    setState(() => _isLoading = false);
    _completeAuth(success: true);
  }

  void _completeAuth({required bool success}) {
    if (success) {
      // 로그인 성공: 메인 페이지로 이동 (이전 화면 모두 제거)
      Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
        AppRoutes.main,
        (route) => false,
      );
    } else {
      // 로그인 취소: 이전 화면으로 돌아가기
      Navigator.of(context, rootNavigator: true).pop(success);
    }
  }

  @override
  Widget build(BuildContext context) {
    final socialEnabled = FeatureFlags.enableSocialLogin;
    final signUpEnabled = FeatureFlags.enableEmailSignUp;

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
                  const SizedBox(height: 20),
                ],
                if (_errorMessage != null)
                  _ErrorBanner(
                    message: _errorMessage!,
                    debugMessage: kDebugMode ? _debugMessage : null,
                  ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    socialEnabled ? '또는 이메일로 로그인' : '이메일로 로그인',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _EmailForm(
                  formKey: _formKey,
                  emailController: _emailController,
                  passwordController: _passwordController,
                  isLoading: _isLoading,
                  onSubmit: _handleEmailLogin,
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
        )
      ],
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
        isEnabled ? textColor : textColor.withOpacity(0.7);
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          disabledBackgroundColor: backgroundColor.withOpacity(0.45),
          disabledForegroundColor: textColor.withOpacity(0.7),
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: borderColor != null
                ? BorderSide(
                    color: borderColor!.withOpacity(isEnabled ? 1 : 0.4))
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

class _EmailForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;
  final VoidCallback onSubmit;

  const _EmailForm({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          TextFormField(
            controller: emailController,
            decoration: const InputDecoration(
              labelText: '이메일',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) => value != null && value.contains('@')
                ? null
                : '올바른 이메일을 입력해주세요.',
            enabled: !isLoading,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: passwordController,
            decoration: const InputDecoration(
              labelText: '비밀번호',
              prefixIcon: Icon(Icons.lock_outlined),
            ),
            obscureText: true,
            validator: (value) => value != null && value.length >= 6
                ? null
                : '비밀번호는 6자 이상 입력해주세요.',
            enabled: !isLoading,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isLoading ? null : onSubmit,
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      '로그인',
                      style: AppTextStyles.buttonMedium,
                    ),
            ),
          ),
        ],
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
