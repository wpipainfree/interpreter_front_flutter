import 'package:flutter/material.dart';

import '../router/app_routes.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class RoleTransitionScreen extends StatelessWidget {
  const RoleTransitionScreen({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.of(context).pushNamed<void>(AppRoutes.roleTransition);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text('\ud0c0\uc778 \ud3c9\uac00\ub85c \uc804\ud658'),
        backgroundColor: AppColors.backgroundWhite,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('\uc774\uc81c \ud0c0\uc778 \ud3c9\uac00\ub85c \ub118\uc5b4\uac11\ub2c8\ub2e4.', style: AppTextStyles.h3),
              const SizedBox(height: 8),
              Text('\uc8fc\ubcc0 \uc0ac\ub78c\uc774 \ubcf4\ub294 \ub098\uc758 \uae30\uc900\uc744 \uc120\ud0dd\ud574\uc694.', style: AppTextStyles.bodyMedium),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: AppColors.textOnPrimary,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '\uacc4\uc18d',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
