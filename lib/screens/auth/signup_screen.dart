import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../utils/app_config.dart';
import '../main_shell.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nicknameController = TextEditingController();

  bool _isLoading = false;
  bool _agreed = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _handleSocialSignUp(String provider) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _authService.loginWithSocial(provider);

    setState(() => _isLoading = false);

    if (result.isSuccess) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Welcome, ${result.user!.nickname}!'),
          backgroundColor: AppColors.secondary,
        ),
      );
      _navigateToDashboard();
    } else {
      setState(() => _errorMessage = result.errorMessage);
    }
  }

  Future<void> _handleEmailSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreed) {
      setState(() => _errorMessage = '약관에 동의해주세요.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _authService.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      nickname: _nicknameController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (result.isSuccess) {
      _navigateToDashboard();
    } else {
      setState(() => _errorMessage = result.errorMessage);
    }
  }

  void _navigateToDashboard() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (AppConfig.freeNavigation) ...[
                _DevBypassBanner(onBypass: _navigateToDashboard),
                const SizedBox(height: 20),
              ],
              const _Header(),
              const SizedBox(height: 28),
              _SocialButton(
                label: '카카오로 3초 만에 시작하기',
                backgroundColor: const Color(0xFFFEE500),
                textColor: const Color(0xFF191919),
                icon: Icons.chat_bubble_outline_rounded,
                onPressed: () => _handleSocialSignUp('kakao'),
              ),
              const SizedBox(height: 12),
              _SocialButton(
                label: 'Apple로 계속하기',
                backgroundColor: Colors.black,
                textColor: Colors.white,
                icon: Icons.apple,
                onPressed: () => _handleSocialSignUp('apple'),
              ),
              const SizedBox(height: 12),
              _SocialButton(
                label: 'Google로 가입하기',
                backgroundColor: Colors.white,
                textColor: AppColors.textPrimary,
                icon: Icons.public,
                borderColor: AppColors.border,
                onPressed: () => _handleSocialSignUp('google'),
              ),
              const SizedBox(height: 20),
              if (_errorMessage != null) _ErrorBanner(message: _errorMessage!),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  '또는 이메일로 가입',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
                ),
              ),
              const SizedBox(height: 12),
              _EmailForm(
                formKey: _formKey,
                emailController: _emailController,
                passwordController: _passwordController,
                nicknameController: _nicknameController,
                isLoading: _isLoading,
                agreed: _agreed,
                onAgreedChanged: (v) => setState(() => _agreed = v),
                onSubmit: _handleEmailSignUp,
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        },
                  child: Text(
                    '이미 계정이 있나요? 로그인',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.secondary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Create Your Structure',
          style: AppTextStyles.h2,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '마음의 구조를 기록하기 위한 첫 걸음',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
          textAlign: TextAlign.center,
        ),
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
  final VoidCallback onPressed;

  const _SocialButton({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
    required this.onPressed,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: borderColor != null ? BorderSide(color: borderColor!) : BorderSide.none,
          ),
        ),
        icon: Icon(icon, size: 20, color: textColor),
        label: Text(
          label,
          style: AppTextStyles.buttonMedium.copyWith(
            color: textColor,
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
  final TextEditingController nicknameController;
  final bool isLoading;
  final bool agreed;
  final ValueChanged<bool> onAgreedChanged;
  final VoidCallback onSubmit;

  const _EmailForm({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.nicknameController,
    required this.isLoading,
    required this.agreed,
    required this.onAgreedChanged,
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
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) =>
                value != null && value.contains('@') ? null : 'Please enter a valid email.',
            enabled: !isLoading,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: passwordController,
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock_outlined),
            ),
            obscureText: true,
            validator: (value) =>
                value != null && value.length >= 6 ? null : 'Password must be at least 6 characters.',
            enabled: !isLoading,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: nicknameController,
            decoration: const InputDecoration(
              labelText: 'Nickname',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (value) =>
                value != null && value.isNotEmpty ? null : 'Please enter a nickname.',
            enabled: !isLoading,
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            value: agreed,
            onChanged: isLoading ? null : (v) => onAgreedChanged(v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: Text(
              '이용약관 및 개인정보 처리에 동의합니다',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 12),
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
                      '가입하기',
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
  const _ErrorBanner({required this.message});

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
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }
}

class _DevBypassBanner extends StatelessWidget {
  final VoidCallback onBypass;
  const _DevBypassBanner({required this.onBypass});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('개발 모드', style: AppTextStyles.labelMedium),
          const SizedBox(height: 4),
          Text(
            '로그인/권한 없이 전체 화면 탐색 가능합니다.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onBypass,
            child: Text(
              '바로 입장',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.secondary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
