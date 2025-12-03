import 'package:flutter/material.dart';
import 'test_intro_screen.dart';

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
  DateTime? _selectedDate;
  bool _termsAgreed = false;
  bool _privacyAgreed = false;

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
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  void _submit() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || !_termsAgreed || !_privacyAgreed) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TestIntroScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
        backgroundColor: const Color(0xFF0F4C81),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: _inputDecoration('이메일', Icons.email),
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                    value != null && value.contains('@') ? null : '이메일을 입력하세요',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: _inputDecoration('비밀번호', Icons.lock),
                obscureText: true,
                validator: (value) =>
                    value != null && value.length >= 6 ? null : '6자 이상 입력하세요',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nicknameController,
                decoration: _inputDecoration('닉네임', Icons.person),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: _inputDecoration('생년월일', Icons.calendar_today),
                  child: Text(
                    _selectedDate != null
                        ? '${_selectedDate!.year}-${_selectedDate!.month}-${_selectedDate!.day}'
                        : '선택하세요',
                  ),
                ),
              ),
              const SizedBox(height: 24),
              CheckboxListTile(
                title: const Text('서비스 이용약관에 동의합니다'),
                value: _termsAgreed,
                onChanged: (v) => setState(() => _termsAgreed = v ?? false),
              ),
              CheckboxListTile(
                title: const Text('개인정보 처리방침에 동의합니다'),
                value: _privacyAgreed,
                onChanged: (v) => setState(() => _privacyAgreed = v ?? false),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F4C81),
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: const Text('가입하기', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
