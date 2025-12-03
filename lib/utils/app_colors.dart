import 'package:flutter/material.dart';

/// 앱 전역 색상 상수 (알폰스 무하 아르누보 스타일)
class AppColors {
  AppColors._();

  // ============================================
  // 브랜드 컬러 (무하 스타일)
  // ============================================

  /// 메인 라벤더 (Primary) - 무하의 대표 색상
  static const Color primary = Color(0xFF9B7EBD);
  static const Color primaryLight = Color(0xFFB8A5D0);
  static const Color primaryDark = Color(0xFF7D5BA6);

  /// 서브 피치/로즈 (Secondary) - 부드럽고 따뜻한 느낌
  static const Color secondary = Color(0xFFE8B4B8);
  static const Color secondaryLight = Color(0xFFF5D4D6);

  /// 액센트 골드 (결과/강조) - 무하의 황금 장식
  static const Color accent = Color(0xFFD4AF37);
  static const Color accentLight = Color(0xFFE6C86E);

  // ============================================
  // 배경 컬러 (무하 스타일)
  // ============================================

  /// 다크 배경 (온보딩, 스플래시) - 깊은 자주색
  static const Color backgroundDark = Color(0xFF4A3C57);
  static const Color backgroundDarkLight = Color(0xFF5E4D6D);

  /// 라이트 배경 (일반 화면) - 크림/아이보리 톤
  static const Color backgroundLight = Color(0xFFFAF7F2);
  static const Color backgroundWhite = Color(0xFFFFFBF5);

  /// 카드 배경 - 부드러운 아이보리
  static const Color cardBackground = Color(0xFFFFFBF5);

  // ============================================
  // 텍스트 컬러 (무하 스타일)
  // ============================================

  static const Color textPrimary = Color(0xFF4A3C57);
  static const Color textSecondary = Color(0xFF6B5B73);
  static const Color textTertiary = Color(0xFF9B8AA1);
  static const Color textHint = Color(0xFFC4B5CC);
  static const Color textOnDark = Color(0xFFFAF7F2);
  static const Color textOnPrimary = Color(0xFFFFFBF5);

  // ============================================
  // 존재 유형별 컬러 (무하 스타일)
  // ============================================

  static const Color typeHarmony = Color(0xFF9CC5A1);    // 조화형 - 세이지 그린
  static const Color typeChallenge = Color(0xFFE8B4B8);  // 도전형 - 로즈
  static const Color typeStability = Color(0xFF8ABED4); // 안정형 - 파스텔 블루
  static const Color typeExplorer = Color(0xFFA98FBC);  // 탐구형 - 라일락
  static const Color typeEmotional = Color(0xFFF5C6CB); // 감성형 - 핑크

  // ============================================
  // 빨간선 / 파란선 (무하 스타일)
  // ============================================

  static const Color redLine = Color(0xFFD88B95);
  static const Color blueLine = Color(0xFF8ABED4);

  // ============================================
  // 상태 컬러 (무하 스타일)
  // ============================================

  static const Color success = Color(0xFF9CC5A1);
  static const Color warning = Color(0xFFE6C86E);
  static const Color error = Color(0xFFD88B95);
  static const Color info = Color(0xFF8ABED4);

  // ============================================
  // 소셜 로그인 컬러
  // ============================================
  
  static const Color kakao = Color(0xFFFEE500);
  static const Color kakaoText = Color(0xFF191919);
  static const Color naver = Color(0xFF03C75A);
  static const Color google = Color(0xFF4285F4);
  static const Color facebook = Color(0xFF1877F2);

  // ============================================
  // 기타 (무하 스타일)
  // ============================================

  static const Color divider = Color(0xFFE8D5E0);
  static const Color border = Color(0xFFD4C5D0);
  static const Color disabled = Color(0xFFC4B5CC);
  static const Color teal = Color(0xFF9CC5A1);

  /// 감정 신호 배경
  static const Color emotionalSignalBg = Color(0xFFFDE9ED);
  static const Color emotionalSignalText = Color(0xFF9B7EBD);

  /// 몸 신호
  static const Color bodySignal = Color(0xFF9CC5A1);

  /// Gap 분석 배경
  static const Color gapAnalysisBg = Color(0xFFFFF8E7);
  static const Color gapAnalysisText = Color(0xFF9B8AA1);

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

