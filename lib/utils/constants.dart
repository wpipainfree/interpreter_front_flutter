/// 앱 전역 상수
class AppConstants {
  AppConstants._();

  // ============================================
  // 기본 정보
  // ============================================
  static const String appName = 'WPI 구조';
  static const String appVersion = '0.1.0';

  // ============================================
  // 검사 설정
  // ============================================
  static const int sampleQuestionCount = 5; // 샘플 문항 수
  static const int fullQuestionCount = 60; // 전체 문항 수
  static const int defaultReminderDays = 30; // 기본 리마인드 주기(일)

  // ============================================
  // UI spacing
  // ============================================
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;

  static const double buttonHeightSmall = 44.0;
  static const double buttonHeightMedium = 52.0;
  static const double buttonHeightLarge = 56.0;

  static const double iconSizeSmall = 20.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeXLarge = 48.0;

  // ============================================
  // Animation
  // ============================================
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  /// 스플래시 노출 시간
  static const Duration splashDuration = Duration(seconds: 2);

  // ============================================
  // 존재 유형 샘플
  // ============================================
  static const List<String> existenceTypes = [
    '조화형',
    '도전형',
    '안정형',
    '탐험형',
    '감성형',
  ];

  // ============================================
  // Likert 옵션
  // ============================================
  static const List<String> likertOptions = [
    '전혀 아니다',
    '아니다',
    '보통이다',
    '그렇다',
    '매우 그렇다',
  ];
}
