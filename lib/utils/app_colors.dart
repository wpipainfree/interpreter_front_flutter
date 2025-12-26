import 'package:flutter/material.dart';

/// 앱 전역 색상 상수
class AppColors {
  AppColors._();

  // ============================================
  // 브랜드 컬러
  // ============================================
  
  /// 메인 블루 (Primary)
  static const Color primary = Color(0xFFA5192B);
  static const Color primaryLight = Color(0xFFC43A4C);
  static const Color primaryDark = Color(0xFF7F121F);
  
  /// 서브 그린 (Secondary - 검사 관련)
  static const Color secondary = Color(0xFF1B2B3A);
  static const Color secondaryLight = Color(0xFF24384A);
  
  /// 액센트 오렌지 (결과/강조)
  static const Color accent = Color(0xFF24384A);
  static const Color accentLight = Color(0xFF3A4C5E);

  // ============================================
  // 배경 컬러
  // ============================================
  
  /// 다크 배경 (온보딩, 스플래시)
  static const Color backgroundDark = Color(0xFF1B2B3A);
  static const Color backgroundDarkLight = Color(0xFF223446);
  
  /// 라이트 배경 (일반 화면)
  static const Color backgroundLight = Color(0xFFF9F8F4);
  static const Color backgroundWhite = Color(0xFFFFFEFA);
  
  /// 카드 배경
  static const Color cardBackground = Color(0xFFFFFEFA);

  // ============================================
  // 텍스트 컬러
  // ============================================
  
  static const Color textPrimary = Color(0xFF1B2B3A);
  static const Color textSecondary = Color(0xFF2F3F4D);
  static const Color textTertiary = Color(0xFF4F5A67);
  static const Color textHint = Color(0xFF77808C);
  static const Color textOnDark = Colors.white;
  static const Color textOnPrimary = Colors.white;

  // ============================================
  // 존재 유형별 컬러
  // ============================================
  
  static const Color typeHarmony = Color(0xFF4CAF50);    // 조화형
  static const Color typeChallenge = Color(0xFFF57C00);  // 도전형
  static const Color typeStability = Color(0xFF2196F3); // 안정형
  static const Color typeExplorer = Color(0xFF9C27B0);  // 탐구형
  static const Color typeEmotional = Color(0xFFE91E63); // 감성형

  // ============================================
  // 빨간선 / 파란선
  // ============================================
  
  static const Color redLine = Color(0xFFE53935);
  static const Color blueLine = Color(0xFF1E88E5);

  // ============================================
  // 상태 컬러
  // ============================================
  
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF2196F3);

  // ============================================
  // 소셜 로그인 컬러
  // ============================================
  
  static const Color kakao = Color(0xFFFEE500);
  static const Color kakaoText = Color(0xFF191919);
  static const Color naver = Color(0xFF03C75A);
  static const Color google = Color(0xFF4285F4);
  static const Color facebook = Color(0xFF1877F2);

  // ============================================
  // 기타
  // ============================================
  
  static const Color divider = Color(0xFFE6E1D9);
  static const Color border = Color(0xFFD8D2C7);
  static const Color disabled = Color(0xFFB7BEC7);
  static const Color teal = Color(0xFF5A7C8A);
  
  /// 감정 신호 배경
  static const Color emotionalSignalBg = Color(0xFFFFE0EC);
  static const Color emotionalSignalText = Color(0xFF880E4F);
  
  /// 몸 신호
  static const Color bodySignal = Color(0xFF4CAF50);
  
  /// Gap 분석 배경
  static const Color gapAnalysisBg = Color(0xFFFFF9C4);
  static const Color gapAnalysisText = Color(0xFF795548);

  // ============================================
  // 유틸리티 메서드
  // ============================================
  
  /// 존재 유형에 따른 색상 반환
  static Color getTypeColor(String type) {
    switch (type) {
      case '조화형':
        return typeHarmony;
      case '도전형':
        return typeChallenge;
      case '안정형':
        return typeStability;
      case '탐구형':
        return typeExplorer;
      case '감성형':
        return typeEmotional;
      default:
        return primary;
    }
  }

  /// 소셜 로그인 제공자에 따른 색상 반환
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

