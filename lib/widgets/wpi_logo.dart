import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// WPI 로고 위젯
class WpiLogo extends StatelessWidget {
  final double? fontSize;
  final Color? color;
  final bool showSubtitle;

  const WpiLogo({
    super.key,
    this.fontSize,
    this.color,
    this.showSubtitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = color ?? AppColors.textOnDark;
    final mainFontSize = fontSize ?? 24;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // WPI 로고 아이콘
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.psychology,
                size: mainFontSize,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            // WPI 텍스트
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WPI',
                  style: TextStyle(
                    fontSize: mainFontSize,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: 1.5,
                  ),
                ),
                if (showSubtitle)
                  Text(
                    '한국심리상담검사센터',
                    style: TextStyle(
                      fontSize: mainFontSize * 0.4,
                      fontWeight: FontWeight.w500,
                      color: textColor.withOpacity(0.9),
                      letterSpacing: 0.5,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/// WPI 작은 로고 (네비게이션용)
class WpiSmallLogo extends StatelessWidget {
  final Color? color;

  const WpiSmallLogo({
    super.key,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(
            Icons.psychology,
            size: 16,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'WPI',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color ?? AppColors.primary,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
