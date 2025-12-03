import 'package:flutter/material.dart';

/// 앱 전역 색상 상수
class AppColors {
  AppColors._();

  // ============================================
  // 브랜드 컬러 (WPI 웹사이트 디자인 매칭)
  // ============================================

  /// 메인 블루 (Primary) - WPI 웹사이트 스타일
  static const Color primary = Color(0xFF4A90E2);
  static const Color primaryLight = Color(0xFF64A8F5);
  static const Color primaryDark = Color(0xFF3478C6);

  /// 서브 퍼플 (Secondary - 검사 관련)
  static const Color secondary = Color(0xFF8B5CF6);
  static const Color secondaryLight = Color(0xFFA78BFA);

  /// 액센트 컬러
  static const Color accent = Color(0xFFFFB800);
  static const Color accentLight = Color(0xFFFFCA28);

  // ============================================
  // 배경 컬러
  // ============================================

  /// 다크 배경 (온보딩, 스플래시)
  static const Color backgroundDark = Color(0xFF1A1A2E);
  static const Color backgroundDarkLight = Color(0xFF252542);

  /// 라이트 배경 (일반 화면) - WPI 웹사이트 스타일
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color backgroundWhite = Colors.white;
  static const Color backgroundBlueLight = Color(0xFFE3F2FD);
  static const Color backgroundPurpleLight = Color(0xFFF3E5F5);

  /// 카드 배경
  static const Color cardBackground = Colors.white;

  // ============================================
  // 텍스트 컬러
  // ============================================
  
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF424242);
  static const Color textTertiary = Color(0xFF666666);
  static const Color textHint = Color(0xFF999999);
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
  
  static const Color divider = Color(0xFFE0E0E0);
  static const Color border = Color(0xFFDDDDDD);
  static const Color disabled = Color(0xFFBDBDBD);
  static const Color teal = Color(0xFF00897B);
  
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

