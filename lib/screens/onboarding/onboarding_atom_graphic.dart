import 'dart:math';

import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';

class OnboardingAtomGraphic extends StatelessWidget {
  const OnboardingAtomGraphic({
    super.key,
    this.size = 220,
    this.showCoreLabels = false,
    this.showDirectionArrow = false,
  });

  final double size;
  final bool showCoreLabels;
  final bool showDirectionArrow;

  @override
  Widget build(BuildContext context) {
    final coreSize = size * 0.34;
    final offsetX = size * 0.13;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: const _AtomOrbitPainter(),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              Transform.translate(
                offset: Offset(-offsetX, 0),
                child: _CoreCircle(
                  size: coreSize,
                  color: AppColors.secondary,
                  label: showCoreLabels ? '기준' : null,
                ),
              ),
              Transform.translate(
                offset: Offset(offsetX, 0),
                child: _CoreCircle(
                  size: coreSize,
                  color: AppColors.primary,
                  label: showCoreLabels ? '믿음' : null,
                ),
              ),
            ],
          ),
          if (showDirectionArrow)
            Positioned(
              right: 6,
              top: size * 0.5 - 14,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: AppColors.secondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CoreCircle extends StatelessWidget {
  const _CoreCircle({
    required this.size,
    required this.color,
    this.label,
  });

  final double size;
  final Color color;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: label == null
          ? null
          : Text(
              label!,
              style: AppTextStyles.labelLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
    );
  }
}

class _AtomOrbitPainter extends CustomPainter {
  const _AtomOrbitPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final minDim = min(size.width, size.height);
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = minDim / 2;

    final bodyRingWidth = minDim * 0.035;
    final bodyRingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = bodyRingWidth
      ..color = AppColors.bodySignal.withOpacity(0.22);
    canvas.drawCircle(
      center,
      outerRadius - bodyRingWidth / 2,
      bodyRingPaint,
    );

    final orbitRadius = outerRadius * 0.67;
    final orbitPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = minDim * 0.012
      ..color = AppColors.border;
    canvas.drawCircle(center, orbitRadius, orbitPaint);

    final dotRadius = minDim * 0.02;
    final dotPaint = Paint()..color = AppColors.primaryLight.withOpacity(0.75);
    final angles = <double>[0.0, 1.15, 2.35, 3.45, 4.65];
    for (final angle in angles) {
      final dx = cos(angle) * orbitRadius;
      final dy = sin(angle) * orbitRadius;
      canvas.drawCircle(center + Offset(dx, dy), dotRadius, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

