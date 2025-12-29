import 'package:flutter/material.dart';

/// 앱 전역 색상 팔레트
class AppColors {
  AppColors._();

  // Primary
  static const Color primary = Color(0xFFA5192B);
  static const Color primaryLight = Color(0xFFC43A4C);
  static const Color primaryDark = Color(0xFF7F121F);

  // Secondary
  static const Color secondary = Color(0xFF1B2B3A);
  static const Color secondaryLight = Color(0xFF24384A);
  static const Color accent = Color(0xFF24384A);
  static const Color accentLight = Color(0xFF3A4C5E);

  // Background
  static const Color backgroundDark = Color(0xFF1B2B3A);
  static const Color backgroundDarkLight = Color(0xFF223446);
  static const Color backgroundLight = Color(0xFFF9F8F4);
  static const Color backgroundWhite = Color(0xFFFFFEFA);
  static const Color cardBackground = Color(0xFFFFFEFA);

  // Text
  static const Color textPrimary = Color(0xFF1B2B3A);
  static const Color textSecondary = Color(0xFF2F3F4D);
  static const Color textTertiary = Color(0xFF4F5A67);
  static const Color textHint = Color(0xFF77808C);
  static const Color textOnDark = Colors.white;
  static const Color textOnPrimary = Colors.white;

  // Type colors
  static const Color typeHarmony = Color(0xFF4CAF50); // 조화형
  static const Color typeChallenge = Color(0xFFF57C00); // 도전형
  static const Color typeStability = Color(0xFF2196F3); // 안정형
  static const Color typeExplorer = Color(0xFF9C27B0); // 탐험형
  static const Color typeEmotional = Color(0xFFE91E63); // 감성형

  // Lines
  static const Color redLine = Color(0xFFE53935);
  static const Color blueLine = Color(0xFF1E88E5);

  // State
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF2196F3);

  // Providers
  static const Color kakao = Color(0xFFFEE500);
  static const Color kakaoText = Color(0xFF191919);
  static const Color naver = Color(0xFF03C75A);
  static const Color google = Color(0xFF4285F4);
  static const Color facebook = Color(0xFF1877F2);

  // Misc
  static const Color divider = Color(0xFFE6E1D9);
  static const Color border = Color(0xFFD8D2C7);
  static const Color disabled = Color(0xFFB7BEC7);
  static const Color teal = Color(0xFF5A7C8A);
  static const Color emotionalSignalBg = Color(0xFFFFE0EC);
  static const Color emotionalSignalText = Color(0xFF880E4F);
  static const Color bodySignal = Color(0xFF4CAF50);
  static const Color gapAnalysisBg = Color(0xFFFFF9C4);
  static const Color gapAnalysisText = Color(0xFF795548);

  static Color getTypeColor(String type) {
    switch (type) {
      case '조화형':
        return typeHarmony;
      case '도전형':
        return typeChallenge;
      case '안정형':
        return typeStability;
      case '탐험형':
        return typeExplorer;
      case '감성형':
        return typeEmotional;
      default:
        return primary;
    }
  }

  static Color getProviderColor(String provider) {
    switch (provider) {
      case 'kakao':
        return kakao;
      case 'naver':
        return naver;
      case 'google':
        return google;
      case 'facebook':
        return facebook;
      default:
        return textTertiary;
    }
  }
}
