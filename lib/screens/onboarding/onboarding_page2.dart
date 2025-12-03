import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

/// 온보딩 페이지 2: WPI는 성격 유형 검사가 아니라, 마음의 MRI입니다
class OnboardingPage2 extends StatelessWidget {
  const OnboardingPage2({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          
          // MRI 아이콘
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.monitor_heart_outlined,
                size: 56,
                color: AppColors.primary,
              ),
            ),
          ),
          
          const SizedBox(height: 40),
          
          // 제목
          const Text(
            'WPI는 성격 유형 검사가 아니라,\n\'마음의 MRI\'입니다',
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
            'WPI는 "당신은 ○○형입니다"라고 딱지 붙이는 검사가 아닙니다.\n\n'
            'WPI는 두 개의 선으로,\n'
            '"나는 어떤 사람이라고 믿고 살아왔는지"\n'
            '"어떤 기준을 지키며 버텨왔는지"를 보여주는\n'
            '마음의 MRI입니다.',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textOnDark.withOpacity(0.8),
              height: 1.7,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // 빨간선 - 파란선 설명
          _buildLineCard(
            color: AppColors.redLine,
            title: '빨간선 (Self-belief)',
            subtitle: '자기 믿음',
            description: '"나는 어떤 사람이어야 한다고 믿고 있는가?"',
          ),
          
          const SizedBox(height: 16),
          
          _buildLineCard(
            color: AppColors.blueLine,
            title: '파란선 (Standard)',
            subtitle: '기준',
            description: '"나는 무엇을 지켜야 존재할 수 있다고 믿고 있는가?"',
          ),
          
          const SizedBox(height: 24),
          
          // 간격 설명
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.warning.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.warning,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '두 선이 멀어질수록,\n마음과 몸은 더 크게 흔들립니다.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textOnDark.withOpacity(0.9),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // 핵심 메시지 박스
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withOpacity(0.3),
                  AppColors.backgroundDark,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.5),
              ),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.format_quote,
                  color: Color(0xFF4A9FD4),
                  size: 32,
                ),
                SizedBox(height: 12),
                Text(
                  'WPI는 점수가 아니라,\n두 선이 만들어낸 "나의 존재 구조"를\n보는 검사입니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textOnDark,
                    height: 1.6,
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

  Widget _buildLineCard({
    required Color color,
    required String title,
    required String subtitle,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundDarkLight,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: color, width: 4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textOnDark.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textOnDark.withOpacity(0.85),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
