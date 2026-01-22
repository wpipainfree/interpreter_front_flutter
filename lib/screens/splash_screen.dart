import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../utils/constants.dart';
import '../utils/feature_flags.dart';
import '../utils/strings.dart';
import '../router/app_routes.dart';
import 'onboarding/onboarding_atom_graphic.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const String _onboardingSeenKey = 'onboarding_seen';

  @override
  void initState() {
    super.initState();
    _routeAfterSplash();
  }

  Future<void> _routeAfterSplash() async {
    await Future.delayed(AppConstants.splashDuration);
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(_onboardingSeenKey) ?? false;
    final shouldShowOnboarding = FeatureFlags.alwaysShowOnboarding || !seen;
    if (!mounted) return;

    Navigator.of(context).pushReplacementNamed(
      shouldShowOnboarding ? AppRoutes.onboarding : AppRoutes.main,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const OnboardingAtomGraphic(size: 200),
              const SizedBox(height: 24),
              Column(
                children: [
                  Text(
                    AppStrings.splashHeadline,
                    style: AppTextStyles.h4,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppStrings.splashSubtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                AppStrings.loading,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
