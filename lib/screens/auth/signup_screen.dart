import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../app/di/app_scope.dart';
import '../../domain/model/signup_request.dart';
import '../../domain/model/terms.dart';
import '../../router/app_routes.dart';
import '../../ui/auth/view_models/signup_view_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  static const _requiredTermTypes = {'TERMS', 'PRIVACY'};

  final SignUpViewModel _viewModel =
      SignUpViewModel(AppScope.instance.authRepository);
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

    final result = await _viewModel.loadCurrentTerms();
    if (!mounted) return;

    result.when(
      success: (bundle) {
        setState(() {
          _serviceCode =
              bundle.serviceCode.isNotEmpty ? bundle.serviceCode : _serviceCode;
          _channelCode =
              bundle.channelCode.isNotEmpty ? bundle.channelCode : _channelCode;
          _terms = bundle.terms;
          _isTermsLoading = false;
        });
      },
      failure: (failure) {
        setState(() {
          _isTermsLoading = false;
          _termsErrorMessage = failure.userMessage;
        });
      },
    );
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
                    'ë²„ì „ ${term.termsVerId} Â· ì‹œí–‰ì¼ ${term.effectiveYmd}',
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
        return 'ì´ìš©ì•½ê´€';
      case 'PRIVACY':
        return 'ê°œì¸ì •ë³´ ì²˜ë¦¬ë°©ì¹¨';
      case 'MARKETING':
        return 'ë§ˆì¼€íŒ… ì •ë³´ ìˆ˜ì‹  ë™ì˜';
      default:
        return type;
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'ì´ë©”ì¼ì„ ìž…ë ¥í•´ì£¼ì„¸ìš”.';
    }
    const pattern = r'^[^@\s]+@[^@\s]+\.[^@\s]+$';
    if (!RegExp(pattern).hasMatch(value.trim())) {
      return 'ì˜¬ë°”ë¥¸ ì´ë©”ì¼ í˜•ì‹ì„ ìž…ë ¥í•´ì£¼ì„¸ìš”.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'ë¹„ë°€ë²ˆí˜¸ë¥¼ ìž…ë ¥í•´ì£¼ì„¸ìš”.';
    }
    const pattern = r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[^A-Za-z\d]).{8,20}$';
    if (!RegExp(pattern).hasMatch(value)) {
      return '8~20ìž, ì˜ë¬¸/ìˆ«ìž/íŠ¹ìˆ˜ë¬¸ìžë¥¼ ëª¨ë‘ í¬í•¨í•´ì•¼ í•©ë‹ˆë‹¤.';
    }
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'ì´ë¦„ì„ ìž…ë ¥í•´ì£¼ì„¸ìš”.';
    }
    return null;
  }

  String? _validateBirthday(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'ìƒë…„ì›”ì¼ì„ ì„ íƒí•´ì£¼ì„¸ìš”.';
    }
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value.trim())) {
      return 'ìƒë…„ì›”ì¼ í˜•ì‹ì´ ì˜¬ë°”ë¥´ì§€ ì•ŠìŠµë‹ˆë‹¤.';
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
      return 'íœ´ëŒ€í° ë²ˆí˜¸ëŠ” ìˆ«ìž ë˜ëŠ” +êµ­ê°€ì½”ë“œ í˜•ì‹ìœ¼ë¡œ ìž…ë ¥í•´ì£¼ì„¸ìš”.';
    }
    return null;
  }

  Future<void> _handleEmailSignUp() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    if (!_hasRequiredTerms) {
      setState(() {
        _errorMessage =
            'í•„ìˆ˜ ì•½ê´€ ì •ë³´ë¥¼ ë¶ˆëŸ¬ì˜¤ì§€ ëª»í•´ ê°€ìž…ì„ ì§„í–‰í•  ìˆ˜ ì—†ìŠµë‹ˆë‹¤. ì•½ê´€ ë‹¤ì‹œ ë¶ˆëŸ¬ì˜¤ê¸°ë¥¼ ì‹œë„í•´ì£¼ì„¸ìš”.';
      });
      return;
    }

    if (!_termsAgreed || !_privacyAgreed) {
      setState(() {
        _errorMessage =
            'í•„ìˆ˜ ì•½ê´€(ì´ìš©ì•½ê´€, ê°œì¸ì •ë³´ ì²˜ë¦¬ë°©ì¹¨)ì— ë™ì˜í•´ì•¼ ê°€ìž…í•  ìˆ˜ ìžˆìŠµë‹ˆë‹¤.';
      });
      return;
    }

    if (_selectedGender == null) {
      setState(() {
        _errorMessage = 'ì„±ë³„ì„ ì„ íƒí•´ì£¼ì„¸ìš”.';
      });
      return;
    }

    final birthdayYmd = _birthdayController.text.trim().replaceAll('-', '');

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _debugMessage = null;
    });

    final result = await _viewModel.signUp(
      SignUpRequest(
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
      ),
    );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    result.when(
      success: (_) => _completeAuth(success: true),
      failure: (failure) {
        setState(() {
          _errorMessage = failure.userMessage;
          _debugMessage = failure.debugMessage;
        });
      },
    );
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
                          labelText: 'ì´ë©”ì¼',
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
                          labelText: 'ë¹„ë°€ë²ˆí˜¸',
                          hintText:
                              '8~20ìž, ì˜ë¬¸/ìˆ«ìž/íŠ¹ìˆ˜ë¬¸ìž í¬í•¨',
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
                          labelText: 'ì´ë¦„',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: _validateName,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedGender,
                        decoration: const InputDecoration(
                          labelText: 'ì„±ë³„',
                          prefixIcon: Icon(Icons.wc_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'ë‚¨', child: Text('ë‚¨')),
                          DropdownMenuItem(value: 'ì—¬', child: Text('ì—¬')),
                        ],
                        onChanged: _isSubmitting
                            ? null
                            : (value) =>
                                setState(() => _selectedGender = value),
                        validator: (value) => value == null
                            ? 'ì„±ë³„ì„ ì„ íƒí•´ì£¼ì„¸ìš”.'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _birthdayController,
                        enabled: !_isSubmitting,
                        readOnly: true,
                        onTap: _pickBirthday,
                        decoration: const InputDecoration(
                          labelText: 'ìƒë…„ì›”ì¼',
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
                          labelText: 'íœ´ëŒ€í° ë²ˆí˜¸ (ì„ íƒ)',
                          hintText: 'ì˜ˆ: 01012345678 ë˜ëŠ” +821012345678',
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
                            'íšŒì›ê°€ìž…',
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
                      'ì´ë¯¸ ê³„ì •ì´ ìžˆìœ¼ì‹ ê°€ìš”? ë¡œê·¸ì¸',
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
          'íšŒì›ê°€ìž…',
          style: AppTextStyles.h2,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'ì•½ê´€ ë™ì˜ í›„ ì´ë©”ì¼ íšŒì›ê°€ìž…ì„ ì§„í–‰í•´ì£¼ì„¸ìš”.',
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
          Text('ì•½ê´€ ë™ì˜', style: AppTextStyles.h5),
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
                  child: const Text('ì•½ê´€ ë‹¤ì‹œ ë¶ˆëŸ¬ì˜¤ê¸°'),
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
                'ì•½ê´€ ì „ì²´ ë™ì˜',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 4),
            _AgreementTile(
              title: 'ì´ìš©ì•½ê´€',
              requiredYn: true,
              value: termsAgreed,
              enabled: !isSubmitting,
              term: terms,
              onChanged: onToggleTerms,
              onViewTerm: onViewTerm,
            ),
            const SizedBox(height: 6),
            _AgreementTile(
              title: 'ê°œì¸ì •ë³´ ì²˜ë¦¬ë°©ì¹¨',
              requiredYn: true,
              value: privacyAgreed,
              enabled: !isSubmitting,
              term: privacy,
              onChanged: onTogglePrivacy,
              onViewTerm: onViewTerm,
            ),
            const SizedBox(height: 6),
            _AgreementTile(
              title: 'ë§ˆì¼€íŒ… ì •ë³´ ìˆ˜ì‹  ë™ì˜',
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
                'í•„ìˆ˜ ì•½ê´€(TERMS/PRIVACY)ì´ ëˆ„ë½ë˜ì–´ ìžˆì–´ ê°€ìž…í•  ìˆ˜ ì—†ìŠµë‹ˆë‹¤.',
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
                    text: requiredYn ? ' (í•„ìˆ˜)' : ' (ì„ íƒ)',
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
              child: const Text('ë³´ê¸°'),
            )
          else
            Text(
              'ë¯¸ì œê³µ',
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
