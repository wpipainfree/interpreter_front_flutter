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
              '이상(변화 방향)도 이어서 할까요?',
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
                  '이상(변화 방향) 검사는 "앞으로 어떤 방향으로 바꾸고 싶은지"를 보는 검사예요.',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  '지금 이어서 진행하거나, 나중에 홈에서 "이상(변화 방향) 이어하기"로 계속할 수 있어요.',
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
                      '이상(변화 방향) 이어하기',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => _close(context, false),
                    child: const Text('나중에 하기'),
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
