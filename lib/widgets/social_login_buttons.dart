import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// 소셜 로그인 버튼 위젯
class SocialLoginButtons extends StatelessWidget {
  final Function(String provider) onSocialLogin;

  const SocialLoginButtons({
    super.key,
    required this.onSocialLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 카카오 로그인
        _SocialButton(
          text: '카카오로 계속하기',
          backgroundColor: const Color(0xFFFEE500),
          textColor: const Color(0xFF191919),
          iconPath: 'kakao',
          onPressed: () => onSocialLogin('kakao'),
        ),
        const SizedBox(height: 12),
        
        // 네이버 로그인
        _SocialButton(
          text: '네이버로 계속하기',
          backgroundColor: const Color(0xFF03C75A),
          textColor: Colors.white,
          iconPath: 'naver',
          onPressed: () => onSocialLogin('naver'),
        ),
        const SizedBox(height: 12),
        
        // 구글 로그인
        _SocialButton(
          text: 'Google로 계속하기',
          backgroundColor: Colors.white,
          textColor: AppColors.textPrimary,
          iconPath: 'google',
          borderColor: const Color(0xFFDDDDDD),
          onPressed: () => onSocialLogin('google'),
        ),
        const SizedBox(height: 12),
        
        // 페이스북 로그인
        _SocialButton(
          text: 'Facebook으로 계속하기',
          backgroundColor: const Color(0xFF1877F2),
          textColor: Colors.white,
          iconPath: 'facebook',
          onPressed: () => onSocialLogin('facebook'),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final String iconPath;
  final Color? borderColor;
  final VoidCallback onPressed;

  const _SocialButton({
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    required this.iconPath,
    required this.onPressed,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: borderColor != null
                ? BorderSide(color: borderColor!)
                : BorderSide.none,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIcon(),
            const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    // 소셜 로그인 아이콘 (아이콘 폰트 대신 텍스트/아이콘 사용)
    switch (iconPath) {
      case 'kakao':
        return Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Color(0xFF191919),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text(
              'K',
              style: TextStyle(
                color: Color(0xFFFEE500),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      case 'naver':
        return Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text(
              'N',
              style: TextStyle(
                color: Color(0xFF03C75A),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      case 'google':
        return Container(
          width: 24,
          height: 24,
          child: const Center(
            child: Text(
              'G',
              style: TextStyle(
                color: Color(0xFF4285F4),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      case 'facebook':
        return Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text(
              'f',
              style: TextStyle(
                color: Color(0xFF1877F2),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      default:
        return const SizedBox(width: 24, height: 24);
    }
  }
}

/// 구분선 위젯
class OrDivider extends StatelessWidget {
  final String text;
  
  const OrDivider({
    super.key,
    this.text = '또는',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: const Color(0xFFE0E0E0),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: const Color(0xFFE0E0E0),
          ),
        ),
      ],
    );
  }
}

