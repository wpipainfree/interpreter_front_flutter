import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

enum AppErrorPrimaryActionStyle { filled, outlined }

class AppErrorView extends StatelessWidget {
  const AppErrorView({
    super.key,
    this.title = '문제가 발생했어요',
    required this.message,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
    this.primaryActionStyle = AppErrorPrimaryActionStyle.outlined,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.icon = Icons.error_outline_rounded,
  });

  final String title;
  final String message;
  final String primaryActionLabel;
  final VoidCallback onPrimaryAction;
  final AppErrorPrimaryActionStyle primaryActionStyle;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final showMessage = !_isRedundantMessage(title, message);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 52, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              Text(
                title,
                style: AppTextStyles.h5,
                textAlign: TextAlign.center,
              ),
              if (showMessage) ...[
                const SizedBox(height: 6),
                Text(
                  message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  if (secondaryActionLabel != null &&
                      onSecondaryAction != null)
                    TextButton(
                      onPressed: onSecondaryAction,
                      child: Text(secondaryActionLabel!),
                    ),
                  _primaryButton(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isRedundantMessage(String title, String message) {
    final normalizedTitle = _normalizeForComparison(title);
    final normalizedMessage = _normalizeForComparison(message);
    if (normalizedMessage.isEmpty) return true;
    return normalizedTitle == normalizedMessage;
  }

  String _normalizeForComparison(String value) {
    var text = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    text = text.replaceAll(RegExp(r'[.!?…]+$'), '').trim();
    return text;
  }

  Widget _primaryButton() {
    const compactMinimumSize = Size(160, 48);
    final style = ButtonStyle(
      minimumSize: WidgetStateProperty.all(compactMinimumSize),
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
    );

    switch (primaryActionStyle) {
      case AppErrorPrimaryActionStyle.filled:
        return ElevatedButton(
          onPressed: onPrimaryAction,
          style: style,
          child: Text(primaryActionLabel),
        );
      case AppErrorPrimaryActionStyle.outlined:
        return OutlinedButton(
          onPressed: onPrimaryAction,
          style: style,
          child: Text(primaryActionLabel),
        );
    }
  }
}
