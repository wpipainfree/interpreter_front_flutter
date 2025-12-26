import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../entry_screen.dart';
import 'onboarding_page1.dart';
import 'onboarding_page2.dart';
import 'onboarding_page3.dart';
import 'onboarding_page4.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<Widget> get _pages => [
        const OnboardingPage1(),
        const OnboardingPage2(),
        const OnboardingPage3(),
        OnboardingPage4(onStart: _goToEntry),
      ];

  void _skipOnboarding() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const EntryScreen()),
    );
  }

  void _goToEntry() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const EntryScreen()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 12),
              _buildHeader(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  children: _pages,
                ),
              ),
              _buildPageIndicator(),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text(
          'Onboarding',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textHint,
            letterSpacing: 0.8,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: _skipOnboarding,
          child: Text(
            'Skip',
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint),
          ),
        ),
      ],
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _pages.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? AppColors.secondary
                : AppColors.textHint.withOpacity(0.4),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
