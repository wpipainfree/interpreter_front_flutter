import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class ContinueToIdealScreen extends StatelessWidget {
  const ContinueToIdealScreen({super.key});

  static Future<bool?> show(BuildContext context) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ContinueToIdealScreen()),
    );
  }

  void _close(BuildContext context, bool value) {
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _close(context, false);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundWhite,
        appBar: AppBar(
          title: const Text('Н?\'НЯ? И¤?Н,кЙнo Н?\'Н-\'Н,o Н,б-%б И1OНs"?'),
          backgroundColor: AppColors.backgroundWhite,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              onPressed: () => _close(context, false),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Н?\'НЯ?Н?? "Й,\'И°? Й?~И3  Н<Н?? Йж"НSц"Н?, Н, бЯ?б~ЙS" Й<"И3,Н~^Нs".',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Н?И,^ Н?\'Н-\'Н,o Н,б-%б~Йc\' И¤°И3мИ°? Й?" Н, Йж.б\'Н`Й<^Й<.',
                  style: AppTextStyles.bodyMedium,
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _close(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: AppColors.textOnPrimary,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Н?\'НЯ?НoмЙнo И3,Н+?',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => _close(context, false),
                    child: const Text('Й,~Н`Н-? б~И,°'),
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

