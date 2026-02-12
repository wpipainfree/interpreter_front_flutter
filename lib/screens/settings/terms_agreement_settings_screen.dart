import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../utils/auth_ui.dart';

class TermsAgreementSettingsScreen extends StatefulWidget {
  const TermsAgreementSettingsScreen({super.key});

  @override
  State<TermsAgreementSettingsScreen> createState() =>
      _TermsAgreementSettingsScreenState();
}

class _TermsAgreementSettingsScreenState
    extends State<TermsAgreementSettingsScreen> {
  final AuthService _authService = AuthService();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String? _debugMessage;

  String _serviceCode = 'PAINFREE_WEB';
  String _channelCode = 'WEB';
  List<TermsDocument> _terms = const [];

  bool _termsAgreed = true;
  bool _privacyAgreed = true;
  bool _marketingAgreed = true;

  @override
  void initState() {
    super.initState();
    _loadTerms();
  }

  TermsDocument? _termByType(String type) {
    for (final term in _terms) {
      if (term.termsType.toUpperCase() == type) {
        return term;
      }
    }
    return null;
  }

  Future<void> _loadTerms() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _debugMessage = null;
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
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = false;
      _errorMessage = result.errorMessage ?? '약관 정보를 불러오지 못했습니다.';
      _debugMessage = result.debugMessage;
    });
  }

  Future<void> _saveAgreements({bool retryOnAuthFailure = true}) async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _debugMessage = null;
    });

    final result = await _authService.saveTermsAgreements(
      serviceCode: _serviceCode,
      channelCode: _channelCode,
      source: 'settings',
      agreements: [
        TermsAgreementItem(termsType: 'TERMS', agreed: _termsAgreed),
        TermsAgreementItem(termsType: 'PRIVACY', agreed: _privacyAgreed),
        TermsAgreementItem(termsType: 'MARKETING', agreed: _marketingAgreed),
      ],
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result.isSuccess) {
      final message = result.message ??
          '동의 설정이 저장되었습니다. '
              '(신규 ${result.insertedCount}건, 변경 ${result.updatedCount}건)';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.success,
        ),
      );
      return;
    }

    if (retryOnAuthFailure && result.errorCode == 'AUTH_REQUIRED') {
      final ok = await AuthUi.promptLogin(context: context);
      if (ok && mounted) {
        await _saveAgreements(retryOnAuthFailure: false);
      }
      return;
    }

    setState(() {
      _errorMessage = result.errorMessage ?? '동의 설정 저장에 실패했습니다.';
      _debugMessage = result.debugMessage;
    });
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

  @override
  Widget build(BuildContext context) {
    final terms = _termByType('TERMS');
    final privacy = _termByType('PRIVACY');
    final marketing = _termByType('MARKETING');
    final requiredUnchecked = !_termsAgreed || !_privacyAgreed;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text('약관 동의 관리', style: AppTextStyles.h4),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_errorMessage != null)
                    _ErrorBanner(
                      message: _errorMessage!,
                      debugMessage: kDebugMode ? _debugMessage : null,
                    ),
                  if (_errorMessage != null) const SizedBox(height: 12),
                  if (_terms.isEmpty)
                    _EmptyTermsView(
                      onRetry: _loadTerms,
                    )
                  else ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        '현재 스코프: $_serviceCode / $_channelCode\n'
                        '동의 상태를 변경 후 저장하면 서버에 즉시 반영됩니다.',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _AgreementSwitchTile(
                      title: '이용약관',
                      requiredYn: true,
                      value: _termsAgreed,
                      enabled: !_isSaving,
                      term: terms,
                      onChanged: (v) => setState(() => _termsAgreed = v),
                      onView:
                          terms != null ? () => _showTermDialog(terms) : null,
                    ),
                    const SizedBox(height: 8),
                    _AgreementSwitchTile(
                      title: '개인정보 처리방침',
                      requiredYn: true,
                      value: _privacyAgreed,
                      enabled: !_isSaving,
                      term: privacy,
                      onChanged: (v) => setState(() => _privacyAgreed = v),
                      onView: privacy != null
                          ? () => _showTermDialog(privacy)
                          : null,
                    ),
                    const SizedBox(height: 8),
                    _AgreementSwitchTile(
                      title: '마케팅 정보 수신 동의',
                      requiredYn: false,
                      value: _marketingAgreed,
                      enabled: !_isSaving,
                      term: marketing,
                      onChanged: (v) => setState(() => _marketingAgreed = v),
                      onView: marketing != null
                          ? () => _showTermDialog(marketing)
                          : null,
                    ),
                    if (requiredUnchecked) ...[
                      const SizedBox(height: 10),
                      Text(
                        '필수 항목을 미동의로 저장하면 서비스 이용에 제한이 생길 수 있습니다.',
                        style: AppTextStyles.captionSmall
                            .copyWith(color: AppColors.error),
                      ),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveAgreements,
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Text(
                                '동의 설정 저장',
                                style: AppTextStyles.buttonMedium,
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _AgreementSwitchTile extends StatelessWidget {
  final String title;
  final bool requiredYn;
  final bool value;
  final bool enabled;
  final TermsDocument? term;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onView;

  const _AgreementSwitchTile({
    required this.title,
    required this.requiredYn,
    required this.value,
    required this.enabled,
    required this.term,
    required this.onChanged,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    text: title,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600),
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
                if (term?.termsExplain != null &&
                    term!.termsExplain.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    term!.termsExplain,
                    style: AppTextStyles.captionSmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          if (onView != null)
            TextButton(
              onPressed: onView,
              child: const Text('보기'),
            ),
          Switch.adaptive(
            value: value,
            onChanged: enabled ? onChanged : null,
          ),
        ],
      ),
    );
  }
}

class _EmptyTermsView extends StatelessWidget {
  final VoidCallback onRetry;

  const _EmptyTermsView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '현재 적용 가능한 약관을 찾을 수 없습니다.',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('다시 시도'),
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
