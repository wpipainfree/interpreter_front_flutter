/// 앱 전역 상수
class AppConstants {
  AppConstants._();

  // ============================================
  // 앱 정보
  // ============================================
  
  static const String appName = 'WPI 마음읽기';
  static const String appVersion = '0.1.0';
  
  // ============================================
  // 검사 관련
  // ============================================
  
  /// 샘플 검사 문항 수
  static const int sampleQuestionCount = 5;
  
  /// 실제 검사 문항 수
  static const int fullQuestionCount = 60;
  
  /// 검사 리마인더 기본 일수
  static const int defaultReminderDays = 30;
  
  // ============================================
  // UI 관련
  // ============================================
  
  /// 기본 패딩
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;
  
  /// 기본 BorderRadius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;
  
  /// 버튼 높이
  static const double buttonHeightSmall = 44.0;
  static const double buttonHeightMedium = 52.0;
  static const double buttonHeightLarge = 56.0;
  
  /// 아이콘 크기
  static const double iconSizeSmall = 20.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeXLarge = 48.0;
  
  // ============================================
  // 애니메이션 관련
  // ============================================
  
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  
  /// 스플래시 화면 표시 시간
  static const Duration splashDuration = Duration(seconds: 2);
  
  // ============================================
  // 존재 유형
  // ============================================
  
  static const List<String> existenceTypes = [
    '조화형',
    '도전형',
    '안정형',
    '탐구형',
    '감성형',
  ];
  
  // ============================================
  // 5점 척도 옵션
  // ============================================
  
  static const List<String> likertOptions = [
    '전혀 그렇지 않다',
    '그렇지 않다',
    '보통이다',
    '그렇다',
    '매우 그렇다',
  ];
}

