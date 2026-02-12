import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../router/app_routes.dart';
import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  static const _requiredTermTypes = {'TERMS', 'PRIVACY'};

  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _mobileController = TextEditingController();

  bool _isSubmitting = false;
  bool _isTermsLoading = true;

  String? _selectedGender;
  String? _errorMessage;
  String? _debugMessage;
  String? _termsErrorMessage;
  String _serviceCode = 'PAINFREE_WEB';
  String _channelCode = 'WEB';

  bool _termsAgreed = false;
  bool _privacyAgreed = false;
  bool _marketingAgreed = true;

  List<TermsDocument> _terms = const [];

  @override
  void initState() {
    super.initState();
    _loadCurrentTerms();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _birthdayController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  TermsDocument? _termByType(String type) {
    for (final term in _terms) {
      if (term.termsType.toUpperCase() == type) {
        return term;
      }
    }
    return null;
  }

  bool get _hasRequiredTerms {
    final availableTypes = _terms.map((e) => e.termsType.toUpperCase()).toSet();
    return _requiredTermTypes.every(availableTypes.contains);
  }

  bool get _allAgreed => _termsAgreed && _privacyAgreed && _marketingAgreed;

  Future<void> _loadCurrentTerms() async {
    setState(() {
      _isTermsLoading = true;
      _termsErrorMessage = null;
    });

    final result = await _authService.getCurrentTerms();
    if (!mounted) return;

    if (result.isSuccess && result.bundle != null) {
      final bundle = result.bundle!;
      setState(() {
        _serviceCode =
            bundle.serviceCode.isNotEmpty ? bundle.serviceCode : _serviceCode;
        _channelCode =
            bundle.channelCode.isNotEmpty ? bundle.channelCode : _channelCode;
        _terms = bundle.terms;
        _isTermsLoading = false;
      });
      return;
    }

    setState(() {
      _isTermsLoading = false;
      _termsErrorMessage = result.errorMessage ?? '약관 정보를 불러오지 못했습니다.';
    });
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 20, 1, 1),
      firstDate: DateTime(1900, 1, 1),
      lastDate: now,
    );

    if (picked == null) return;
    final y = picked.year.toString().padLeft(4, '0');
    final m = picked.month.toString().padLeft(2, '0');
    final d = picked.day.toString().padLeft(2, '0');
    _birthdayController.text = '$y-$m-$d';
  }

  void _showTermDialog(TermsDocument term) {
    final contentFormat = term.contentFormat.toLowerCase();
    final isAppScope = _channelCode.toUpperCase().contains('APP') ||
        _serviceCode.toUpperCase().endsWith('_APP');
    final isMarkdown =
        contentFormat == 'markdown' || (contentFormat == 'auto' && isAppScope);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: AppColors.backgroundWhite,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SizedBox(
            width: double.infinity,
            height: MediaQuery.of(dialogContext).size.height * 0.8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _termTitle(term.termsType),
                          style: AppTextStyles.h5,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: isMarkdown
                        ? MarkdownBody(data: term.content)
                        : SelectableText(
                            _stripHtml(term.content),
                            style: AppTextStyles.bodySmall,
                          ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text(
                    '버전 ${term.termsVerId} · 시행일 ${term.effectiveYmd}',
                    style: AppTextStyles.captionSmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _stripHtml(String html) {
    var text = html;
    text = text.replaceAll(
      RegExp(r'<br\s*/?>', caseSensitive: false),
      '\n',
    );
    text = text.replaceAll(
      RegExp(r'</p>', caseSensitive: false),
      '\n\n',
    );
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');
    text = text.replaceAll('&nbsp;', ' ');
    text = text.replaceAll('&amp;', '&');
    text = text.replaceAll('&lt;', '<');
    text = text.replaceAll('&gt;', '>');
    return text.trim();
  }

  String _termTitle(String type) {
    switch (type.toUpperCase()) {
      case 'TERMS':
        return '이용약관';
      case 'PRIVACY':
        return '개인정보 처리방침';
      case 'MARKETING':
        return '마케팅 정보 수신 동의';
      default:
        return type;
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '이메일을 입력해주세요.';
    }
    const pattern = r'^[^@\s]+@[^@\s]+\.[^@\s]+$';
    if (!RegExp(pattern).hasMatch(value.trim())) {
      return '올바른 이메일 형식을 입력해주세요.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return '비밀번호를 입력해주세요.';
    }
    const pattern = r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[^A-Za-z\d]).{8,20}$';
    if (!RegExp(pattern).hasMatch(value)) {
      return '8~20자, 영문/숫자/특수문자를 모두 포함해야 합니다.';
    }
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '이름을 입력해주세요.';
    }
    return null;
  }

  String? _validateBirthday(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '생년월일을 선택해주세요.';
    }
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value.trim())) {
      return '생년월일 형식이 올바르지 않습니다.';
    }
    return null;
  }

  String? _validateMobile(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final cleaned =
        value.trim().replaceAll(RegExp(r'\s+'), '').replaceAll('-', '');
    if (!RegExp(r'^\+?\d+$').hasMatch(cleaned)) {
      return '휴대폰 번호는 숫자 또는 +국가코드 형식으로 입력해주세요.';
    }
    return null;
  }

  Future<void> _handleEmailSignUp() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    if (!_hasRequiredTerms) {
      setState(() {
        _errorMessage = '필수 약관 정보를 불러오지 못해 가입을 진행할 수 없습니다. 약관 다시 불러오기를 시도해주세요.';
      });
      return;
    }

    if (!_termsAgreed || !_privacyAgreed) {
      setState(() {
        _errorMessage = '필수 약관(이용약관, 개인정보 처리방침)에 동의해야 가입할 수 있습니다.';
      });
      return;
    }

    if (_selectedGender == null) {
      setState(() {
        _errorMessage = '성별을 선택해주세요.';
      });
      return;
    }

    final birthdayYmd = _birthdayController.text.trim().replaceAll('-', '');

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _debugMessage = null;
    });

    final result = await _authService.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      gender: _selectedGender!,
      birthdayYmd: birthdayYmd,
      termsAgreed: _termsAgreed,
      privacyAgreed: _privacyAgreed,
      marketingAgreed: _marketingAgreed,
      serviceCode: _serviceCode,
      channelCode: _channelCode,
      mobileNumber: _mobileController.text.trim(),
    );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (result.isSuccess) {
      _completeAuth(success: true);
      return;
    }

    setState(() {
      _errorMessage = result.errorMessage;
      _debugMessage = result.debugMessage;
    });
  }

  void _completeAuth({required bool success}) {
    Navigator.of(context, rootNavigator: true).pop(success);
  }

  @override
  Widget build(BuildContext context) {
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
                const _Header(),
                const SizedBox(height: 24),
                if (_errorMessage != null)
                  _ErrorBanner(
                    message: _errorMessage!,
                    debugMessage: kDebugMode ? _debugMessage : null,
                  ),
                const SizedBox(height: 12),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        enabled: !_isSubmitting,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: '이메일',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        enabled: !_isSubmitting,
                        obscureText: true,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: '비밀번호',
                          hintText: '8~20자, 영문/숫자/특수문자 포함',
                          prefixIcon: Icon(Icons.lock_outlined),
                        ),
                        validator: _validatePassword,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nameController,
                        enabled: !_isSubmitting,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: '이름',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: _validateName,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedGender,
                        decoration: const InputDecoration(
                          labelText: '성별',
                          prefixIcon: Icon(Icons.wc_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(value: '남', child: Text('남')),
                          DropdownMenuItem(value: '여', child: Text('여')),
                        ],
                        onChanged: _isSubmitting
                            ? null
                            : (value) =>
                                setState(() => _selectedGender = value),
                        validator: (value) =>
                            value == null ? '성별을 선택해주세요.' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _birthdayController,
                        enabled: !_isSubmitting,
                        readOnly: true,
                        onTap: _pickBirthday,
                        decoration: const InputDecoration(
                          labelText: '생년월일',
                          hintText: 'YYYY-MM-DD',
                          prefixIcon: Icon(Icons.cake_outlined),
                        ),
                        validator: _validateBirthday,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _mobileController,
                        enabled: !_isSubmitting,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: '휴대폰 번호 (선택)',
                          hintText: '예: 01012345678 또는 +821012345678',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        validator: _validateMobile,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _TermsSection(
                  isLoading: _isTermsLoading,
                  errorMessage: _termsErrorMessage,
                  isSubmitting: _isSubmitting,
                  hasRequiredTerms: _hasRequiredTerms,
                  termsAgreed: _termsAgreed,
                  privacyAgreed: _privacyAgreed,
                  marketingAgreed: _marketingAgreed,
                  allAgreed: _allAgreed,
                  terms: _termByType('TERMS'),
                  privacy: _termByType('PRIVACY'),
                  marketing: _termByType('MARKETING'),
                  onRetry: _loadCurrentTerms,
                  onToggleAll: (v) {
                    final checked = v ?? false;
                    setState(() {
                      _termsAgreed = checked;
                      _privacyAgreed = checked;
                      _marketingAgreed = checked;
                    });
                  },
                  onToggleTerms: (v) =>
                      setState(() => _termsAgreed = v ?? false),
                  onTogglePrivacy: (v) =>
                      setState(() => _privacyAgreed = v ?? false),
                  onToggleMarketing: (v) =>
                      setState(() => _marketingAgreed = v ?? false),
                  onViewTerm: (term) => _showTermDialog(term),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSubmitting || _isTermsLoading
                        ? null
                        : _handleEmailSignUp,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            '회원가입',
                            style: AppTextStyles.buttonMedium,
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            Navigator.of(context, rootNavigator: true)
                                .pushReplacementNamed(AppRoutes.login);
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
              ],
            ),
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
          '회원가입',
          style: AppTextStyles.h2,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '약관 동의 후 이메일 회원가입을 진행해주세요.',
          style:
              AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _TermsSection extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final bool isSubmitting;
  final bool hasRequiredTerms;
  final bool termsAgreed;
  final bool privacyAgreed;
  final bool marketingAgreed;
  final bool allAgreed;
  final TermsDocument? terms;
  final TermsDocument? privacy;
  final TermsDocument? marketing;
  final VoidCallback onRetry;
  final ValueChanged<bool?> onToggleAll;
  final ValueChanged<bool?> onToggleTerms;
  final ValueChanged<bool?> onTogglePrivacy;
  final ValueChanged<bool?> onToggleMarketing;
  final ValueChanged<TermsDocument> onViewTerm;

  const _TermsSection({
    required this.isLoading,
    required this.errorMessage,
    required this.isSubmitting,
    required this.hasRequiredTerms,
    required this.termsAgreed,
    required this.privacyAgreed,
    required this.marketingAgreed,
    required this.allAgreed,
    required this.terms,
    required this.privacy,
    required this.marketing,
    required this.onRetry,
    required this.onToggleAll,
    required this.onToggleTerms,
    required this.onTogglePrivacy,
    required this.onToggleMarketing,
    required this.onViewTerm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('약관 동의', style: AppTextStyles.h5),
          const SizedBox(height: 8),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (errorMessage != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  errorMessage!,
                  style:
                      AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: isSubmitting ? null : onRetry,
                  child: const Text('약관 다시 불러오기'),
                ),
              ],
            )
          else ...[
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: allAgreed,
              onChanged: isSubmitting ? null : onToggleAll,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                '약관 전체 동의',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 4),
            _AgreementTile(
              title: '이용약관',
              requiredYn: true,
              value: termsAgreed,
              enabled: !isSubmitting,
              term: terms,
              onChanged: onToggleTerms,
              onViewTerm: onViewTerm,
            ),
            const SizedBox(height: 6),
            _AgreementTile(
              title: '개인정보 처리방침',
              requiredYn: true,
              value: privacyAgreed,
              enabled: !isSubmitting,
              term: privacy,
              onChanged: onTogglePrivacy,
              onViewTerm: onViewTerm,
            ),
            const SizedBox(height: 6),
            _AgreementTile(
              title: '마케팅 정보 수신 동의',
              requiredYn: false,
              value: marketingAgreed,
              enabled: !isSubmitting,
              term: marketing,
              onChanged: onToggleMarketing,
              onViewTerm: onViewTerm,
            ),
            if (!hasRequiredTerms) ...[
              const SizedBox(height: 8),
              Text(
                '필수 약관(TERMS/PRIVACY)이 누락되어 있어 가입할 수 없습니다.',
                style:
                    AppTextStyles.captionSmall.copyWith(color: AppColors.error),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _AgreementTile extends StatelessWidget {
  final String title;
  final bool requiredYn;
  final bool value;
  final bool enabled;
  final TermsDocument? term;
  final ValueChanged<bool?> onChanged;
  final ValueChanged<TermsDocument> onViewTerm;

  const _AgreementTile({
    required this.title,
    required this.requiredYn,
    required this.value,
    required this.enabled,
    required this.term,
    required this.onChanged,
    required this.onViewTerm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
      ),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: enabled ? onChanged : null,
          ),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: title,
                style: AppTextStyles.bodySmall,
                children: [
                  TextSpan(
                    text: requiredYn ? ' (필수)' : ' (선택)',
                    style: AppTextStyles.captionSmall.copyWith(
                      color: requiredYn
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (term != null)
            TextButton(
              onPressed: () => onViewTerm(term!),
              child: const Text('보기'),
            )
          else
            Text(
              '미제공',
              style:
                  AppTextStyles.captionSmall.copyWith(color: AppColors.error),
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
