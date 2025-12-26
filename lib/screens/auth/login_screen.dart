import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../dashboard_screen.dart';
import 'signup_screen.dart';

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

  Future<void> _handleEmailLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _authService.loginWithEmail(
      _emailController.text.trim(),
      _passwordController.text,
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
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
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
              const _LoginHeader(),
              const SizedBox(height: 28),
              _SocialButton(
                label: '카카오로 3초 만에 시작하기',
                backgroundColor: const Color(0xFFFEE500),
                textColor: const Color(0xFF191919),
                icon: Icons.chat_bubble_outline_rounded,
                onPressed: () => _handleSocialLogin('kakao'),
              ),
              const SizedBox(height: 12),
              _SocialButton(
                label: 'Apple로 계속하기',
                backgroundColor: Colors.black,
                textColor: Colors.white,
                icon: Icons.apple,
                onPressed: () => _handleSocialLogin('apple'),
              ),
              const SizedBox(height: 12),
              _SocialButton(
                label: 'Google로 로그인',
                backgroundColor: Colors.white,
                textColor: AppColors.textPrimary,
                icon: Icons.public,
                borderColor: AppColors.border,
                onPressed: () => _handleSocialLogin('google'),
              ),
              const SizedBox(height: 20),
              if (_errorMessage != null) _ErrorBanner(message: _errorMessage!),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  '또는 이메일로 로그인',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textHint,
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
              Center(
                child: TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SignUpScreen()),
                          );
                        },
                  child: Text(
                    '이메일로 회원가입',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.secondary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _isLoading ? null : _navigateToDashboard,
                  child: Text(
                    '임시 접근 (개발용)',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textHint,
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

class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Sign in to Your Structure',
          style: AppTextStyles.h2,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '나의 마음 구조를 분석하고 기록합니다',
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
