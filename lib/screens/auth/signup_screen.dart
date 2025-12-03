import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/social_login_buttons.dart';
import '../dashboard_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _authService = AuthService();
  
  DateTime? _selectedDate;
  bool _termsAgreed = false;
  bool _privacyAgreed = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _showEmailForm = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 20, now.month, now.day),
      firstDate: DateTime(1950),
      lastDate: now,
      locale: const Locale('ko', 'KR'),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
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
          content: Text('${result.user!.nickname}님, 가입을 환영합니다!'),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
      _navigateToDashboard();
    } else {
      setState(() => _errorMessage = result.errorMessage);
    }
  }

  Future<void> _handleEmailSignUp() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    
    if (!isValid) return;
    
    if (!_termsAgreed || !_privacyAgreed) {
      setState(() => _errorMessage = '이용약관과 개인정보 처리방침에 동의해주세요.');
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
      birthDate: _selectedDate,
    );

    setState(() => _isLoading = false);

    if (result.isSuccess) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result.user!.nickname}님, 가입을 환영합니다!'),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
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
      appBar: AppBar(
        title: const Text('회원가입'),
        backgroundColor: const Color(0xFF0F4C81),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            
            // 헤더 텍스트
            const Text(
              '간편하게 시작하세요',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '소셜 계정으로 빠르게 가입할 수 있습니다',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 32),

            // 소셜 로그인 버튼들
            SocialLoginButtons(
              onSocialLogin: _handleSocialSignUp,
            ),
            
            const SizedBox(height: 24),
            
            // 구분선
            const OrDivider(text: '또는 이메일로 가입'),
            
            const SizedBox(height: 16),

            // 이메일 가입 토글 버튼
            if (!_showEmailForm)
              OutlinedButton(
                onPressed: () => setState(() => _showEmailForm = true),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(color: Color(0xFF0F4C81)),
                ),
                child: const Text(
                  '이메일로 가입하기',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF0F4C81),
                  ),
                ),
              ),

            // 이메일 가입 폼
            if (_showEmailForm) ...[
              // 에러 메시지
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      decoration: _inputDecoration('이메일', Icons.email_outlined),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) =>
                          value != null && value.contains('@') ? null : '올바른 이메일을 입력하세요',
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: _inputDecoration('비밀번호', Icons.lock_outlined),
                      obscureText: true,
                      validator: (value) =>
                          value != null && value.length >= 6 ? null : '6자 이상 입력하세요',
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nicknameController,
                      decoration: _inputDecoration('닉네임', Icons.person_outlined),
                      validator: (value) =>
                          value != null && value.isNotEmpty ? null : '닉네임을 입력하세요',
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _isLoading ? null : _pickDate,
                      child: InputDecorator(
                        decoration: _inputDecoration('생년월일 (선택)', Icons.calendar_today_outlined),
                        child: Text(
                          _selectedDate != null
                              ? '${_selectedDate!.year}년 ${_selectedDate!.month}월 ${_selectedDate!.day}일'
                              : '선택하세요',
                          style: TextStyle(
                            color: _selectedDate != null ? Colors.black87 : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // 약관 동의
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          CheckboxListTile(
                            title: const Text(
                              '서비스 이용약관에 동의합니다 (필수)',
                              style: TextStyle(fontSize: 14),
                            ),
                            value: _termsAgreed,
                            onChanged: _isLoading
                                ? null
                                : (v) => setState(() => _termsAgreed = v ?? false),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                            dense: true,
                          ),
                          const Divider(height: 1),
                          CheckboxListTile(
                            title: const Text(
                              '개인정보 처리방침에 동의합니다 (필수)',
                              style: TextStyle(fontSize: 14),
                            ),
                            value: _privacyAgreed,
                            onChanged: _isLoading
                                ? null
                                : (v) => setState(() => _privacyAgreed = v ?? false),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                            dense: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleEmailSignUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F4C81),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor: Colors.grey.shade300,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                '가입하기',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // 로그인 링크
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '이미 계정이 있으신가요? ',
                  style: TextStyle(color: Color(0xFF666666)),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Text(
                    '로그인',
                    style: TextStyle(
                      color: Color(0xFF0F4C81),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }
}
