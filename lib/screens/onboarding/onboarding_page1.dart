import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

/// 온보딩 페이지 1: 마음은 감정이 아니라, 나의 '존재 구조'입니다
class OnboardingPage1 extends StatelessWidget {
  const OnboardingPage1({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          
          // 아이콘
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.psychology_outlined,
                size: 56,
                color: AppColors.primary,
              ),
            ),
          ),
          
          const SizedBox(height: 40),
          
          // 제목
          const Text(
            '마음은 감정이 아니라,\n나의 \'존재 구조\'입니다',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textOnDark,
              height: 1.3,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 서브텍스트
          Text(
            '우리는 보통 마음을 "불안, 우울, 예민함" 같은 감정으로만 설명합니다.\n\n'
            'WPI가 보는 마음은 감정 그 자체가 아니라,\n'
            '내가 스스로를 지탱하기 위해 세워온 기준과 믿음의 구조입니다.',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textOnDark.withOpacity(0.8),
              height: 1.7,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // 핵심 포인트 불릿
          _buildBulletPoint(
            '감정은 "문제"가 아니라, 존재가 보내는 신호입니다.',
            Icons.notifications_active_outlined,
          ),
          const SizedBox(height: 16),
          _buildBulletPoint(
            '그 신호 뒤에는 내가 세워온 기준과 믿음이 있습니다.',
            Icons.layers_outlined,
          ),
          const SizedBox(height: 16),
          _buildBulletPoint(
            '마음을 이해하려면, 감정이 아니라 구조를 봐야 합니다.',
            Icons.visibility_outlined,
          ),
          
          const SizedBox(height: 40),
          
          // 하단 강조 박스
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.backgroundDarkLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '핵심',
                        style: TextStyle(
                          color: AppColors.textOnPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '마음은 감정의 문제가 아니라\n존재가 흔들릴 때 나타나는 구조 신호입니다.',
                  style: TextStyle(
                    color: AppColors.textOnDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: const Color(0xFF4A9FD4),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textOnDark.withOpacity(0.9),
                height: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
