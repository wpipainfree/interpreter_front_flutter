import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

/// 온보딩 페이지 3: 지금 겪는 마음의 어려움은 '고장'이 아니라 신호입니다
class OnboardingPage3 extends StatelessWidget {
  const OnboardingPage3({super.key});

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
                color: AppColors.secondary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.healing_outlined,
                size: 56,
                color: AppColors.success,
              ),
            ),
          ),
          
          const SizedBox(height: 40),
          
          // 제목
          const Text(
            '지금 겪는 마음의 어려움은\n\'고장\'이 아니라 신호입니다',
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
            '불안, 무기력, 관계 스트레스, 반복되는 패턴들은\n'
            '"내가 잘못된 사람이라서"가 아니라,\n'
            '지금의 기준과 믿음으로는 더 이상 버티기 어렵다는 신호일 수 있습니다.',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textOnDark.withOpacity(0.8),
              height: 1.7,
            ),
          ),
          
          const SizedBox(height: 28),
          
          // 예시 문장들
          _buildSignalExample(
            emoji: '😴',
            symptom: '"잠이 잘 안 와요"',
            meaning: '과도하게 긴장된 존재의 경보',
          ),
          const SizedBox(height: 12),
          _buildSignalExample(
            emoji: '😰',
            symptom: '"늘 불안하고 공허해요"',
            meaning: '기준과 믿음이 서로 충돌하는 자리',
          ),
          const SizedBox(height: 12),
          _buildSignalExample(
            emoji: '😔',
            symptom: '"관계가 너무 힘들어요"',
            meaning: '나를 지탱하던 방식이 더 이상 통하지 않는 신호',
          ),
          
          const SizedBox(height: 28),
          
          // 핵심 포인트 불릿
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundDarkLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildCheckPoint('WPI는 지금 내 삶에서 어디가 흔들리고 있는지 보여줍니다.'),
                const SizedBox(height: 12),
                _buildCheckPoint('감정과 몸의 신호를 병이 아닌 구조로 읽도록 도와줍니다.'),
                const SizedBox(height: 12),
                _buildCheckPoint('"내가 왜 이런지"를 설명할 언어를 갖게 됩니다.'),
              ],
            ),
          ),
          
          const SizedBox(height: 28),
          
          // 강조 인용문
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.secondary.withOpacity(0.2),
                  AppColors.backgroundDark,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.success.withOpacity(0.4),
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.format_quote,
                  color: AppColors.success,
                  size: 28,
                ),
                const SizedBox(height: 12),
                Text(
                  '감정과 통증은 병이 아니라\n존재가 보낸 구조 신호입니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textOnDark.withOpacity(0.9),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 28),
          
          // 마무리 문장
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                Text(
                  '이제, 당신의 WPI를 통해',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4A9FD4),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '당신의 마음이 어디서,\n어떻게 살아왔는지\n함께 읽어보겠습니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textOnDark,
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

  Widget _buildSignalExample({
    required String emoji,
    required String symptom,
    required String meaning,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundDarkLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  symptom,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textOnDark,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.arrow_forward,
                      size: 14,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        meaning,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textOnDark.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.check_circle,
          size: 20,
          color: AppColors.success,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textOnDark.withOpacity(0.9),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
