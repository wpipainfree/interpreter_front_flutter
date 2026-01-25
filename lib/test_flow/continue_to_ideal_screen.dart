import 'package:flutter/material.dart';

import '../router/app_routes.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class ContinueToIdealScreen extends StatelessWidget {
  const ContinueToIdealScreen({super.key});

  static Future<bool?> show(BuildContext context) {
    return Navigator.of(context).pushNamed<bool>(AppRoutes.continueToIdeal);
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
          title: const Text(
            '\uc774\uc0c1(\ubcc0\ud654 \ubc29\ud5a5)\ub3c4 \uc774\uc5b4\uc11c \ud560\uae4c\uc694?',
          ),
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
                  '\uc774\uc0c1(\ubcc0\ud654 \ubc29\ud5a5) \uac80\uc0ac\ub294 "\uc55e\uc73c\ub85c \uc5b4\ub5a4 \ubc29\ud5a5\uc73c\ub85c \ubc14\uafb8\uace0 \uc2f6\uc740\uc9c0"\ub97c \ubcf4\ub294 \uac80\uc0ac\uc608\uc694.',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  '\uc9c0\uae08 \uc774\uc5b4\uc11c \uc9c4\ud589\ud558\uac70\ub098, \ub098\uc911\uc5d0 \ud648\uc5d0\uc11c "\uc774\uc0c1(\ubcc0\ud654 \ubc29\ud5a5) \uc774\uc5b4\ud558\uae30"\ub85c \uacc4\uc18d\ud560 \uc218 \uc788\uc5b4\uc694.',
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
                      '\uc774\uc0c1(\ubcc0\ud654 \ubc29\ud5a5) \uc774\uc5b4\ud558\uae30',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => _close(context, false),
                    child: const Text('\ub098\uc911\uc5d0 \ud558\uae30'),
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
