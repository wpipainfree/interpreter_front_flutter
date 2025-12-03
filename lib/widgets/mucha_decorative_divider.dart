import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// 무하 스타일의 장식적인 구분선
class MuchaDecorativeDivider extends StatelessWidget {
  final double height;
  final Color? color;

  const MuchaDecorativeDivider({
    super.key,
    this.height = 40,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final dividerColor = color ?? AppColors.primary.withOpacity(0.3);

    return SizedBox(
      height: height,
      child: Row(
        children: [
          Expanded(
            child: CustomPaint(
              painter: _MuchaLinePainter(color: dividerColor),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.4),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: CustomPaint(
              painter: _MuchaLinePainter(color: dividerColor),
            ),
          ),
        ],
      ),
    );
  }
}

/// 무하 스타일의 곡선 라인 페인터
class _MuchaLinePainter extends CustomPainter {
  final Color color;

  _MuchaLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    final midY = size.height / 2;

    // 우아한 곡선 그리기
    path.moveTo(0, midY);
    path.quadraticBezierTo(
      size.width * 0.25,
      midY - 5,
      size.width * 0.5,
      midY,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      midY + 5,
      size.width,
      midY,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 무하 스타일의 장식적인 프레임
class MuchaDecorativeFrame extends StatelessWidget {
  final Widget child;
  final Color? borderColor;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;

  const MuchaDecorativeFrame({
    super.key,
    required this.child,
    this.borderColor,
    this.backgroundColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: borderColor ?? AppColors.primary.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (borderColor ?? AppColors.primary).withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 모서리 장식
          Positioned(
            top: 0,
            left: 0,
            child: _CornerOrnament(color: borderColor ?? AppColors.primary),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Transform.flip(
              flipX: true,
              child: _CornerOrnament(color: borderColor ?? AppColors.primary),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            child: Transform.flip(
              flipY: true,
              child: _CornerOrnament(color: borderColor ?? AppColors.primary),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Transform.flip(
              flipX: true,
              flipY: true,
              child: _CornerOrnament(color: borderColor ?? AppColors.primary),
            ),
          ),
          // 내용
          child,
        ],
      ),
    );
  }
}

/// 모서리 장식 요소
class _CornerOrnament extends StatelessWidget {
  final Color color;

  const _CornerOrnament({required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(30, 30),
      painter: _CornerOrnamentPainter(color: color.withOpacity(0.4)),
    );
  }
}

class _CornerOrnamentPainter extends CustomPainter {
  final Color color;

  _CornerOrnamentPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();

    // 우아한 곡선 모서리 장식
    path.moveTo(0, size.height * 0.5);
    path.quadraticBezierTo(
      0,
      0,
      size.width * 0.5,
      0,
    );

    canvas.drawPath(path, paint);

    // 작은 원 장식
    final circlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.35, size.height * 0.35),
      2,
      circlePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
