import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../app/di/app_scope.dart';
import '../../domain/model/terms.dart';
import '../../ui/auth/view_models/terms_agreement_settings_view_model.dart';
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
  final TermsAgreementSettingsViewModel _viewModel =
      TermsAgreementSettingsViewModel(AppScope.instance.authRepository);

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
          _isLoading = false;
        });
      },
      failure: (failure) {
        setState(() {
          _isLoading = false;
          _errorMessage = failure.userMessage;
          _debugMessage = failure.debugMessage;
        });
      },
    );
  }

  Future<void> _saveAgreements({bool retryOnAuthFailure = true}) async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _debugMessage = null;
    });

    final result = await _viewModel.saveTermsAgreements(
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

    result.when(
      success: (summary) {
        final message = summary.message ??
            'ë™ì˜ ì„¤ì •ì´ ì €ìž¥ë˜ì—ˆìŠµë‹ˆë‹¤. '
                '(ì‹ ê·œ ${summary.insertedCount}ê±´, ë³€ê²½ ${summary.updatedCount}ê±´)';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.success,
          ),
        );
      },
      failure: (failure) async {
        if (retryOnAuthFailure && failure.hasCode('AUTH_REQUIRED')) {
          final ok = await AuthUi.promptLogin(context: context);
          if (ok && mounted) {
            await _saveAgreements(retryOnAuthFailure: false);
          }
          return;
        }

        if (!mounted) return;
        setState(() {
          _errorMessage = failure.userMessage;
          _debugMessage = failure.debugMessage;
        });
      },
    );
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
        title: Text('ì•½ê´€ ë™ì˜ ê´€ë¦¬', style: AppTextStyles.h4),
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
                        'í˜„ìž¬ ìŠ¤ì½”í”„: $_serviceCode / $_channelCode\n'
                        'ë™ì˜ ìƒíƒœë¥¼ ë³€ê²½ í›„ ì €ìž¥í•˜ë©´ ì„œë²„ì— ì¦‰ì‹œ ë°˜ì˜ë©ë‹ˆë‹¤.',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _AgreementSwitchTile(
                      title: 'ì´ìš©ì•½ê´€',
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
                      title: 'ê°œì¸ì •ë³´ ì²˜ë¦¬ë°©ì¹¨',
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
                      title: 'ë§ˆì¼€íŒ… ì •ë³´ ìˆ˜ì‹  ë™ì˜',
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
                        'í•„ìˆ˜ í•­ëª©ì„ ë¯¸ë™ì˜ë¡œ ì €ìž¥í•˜ë©´ ì„œë¹„ìŠ¤ ì´ìš©ì— ì œí•œì´ ìƒê¸¸ ìˆ˜ ìžˆìŠµë‹ˆë‹¤.',
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
                                'ë™ì˜ ì„¤ì • ì €ìž¥',
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
              child: const Text('ë³´ê¸°'),
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
            'í˜„ìž¬ ì ìš© ê°€ëŠ¥í•œ ì•½ê´€ì„ ì°¾ì„ ìˆ˜ ì—†ìŠµë‹ˆë‹¤.',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('ë‹¤ì‹œ ì‹œë„'),
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
