/// Feature flags for QA/development.
///
/// Usage (example):
/// `flutter run --dart-define=WPI_ALWAYS_SHOW_ONBOARDING=true`
class FeatureFlags {
  FeatureFlags._();

  /// When true, onboarding shows on every app launch (ignores `onboarding_seen`).
  static const bool alwaysShowOnboarding = bool.fromEnvironment(
    'WPI_ALWAYS_SHOW_ONBOARDING',
    defaultValue: false,
  );

  /// When true, show social login buttons (Kakao/Apple/Google).
  static const bool enableSocialLogin = bool.fromEnvironment(
    'WPI_ENABLE_SOCIAL_LOGIN',
    defaultValue: false,
  );

  /// When true, enable the email sign-up flow.
  static const bool enableEmailSignUp = bool.fromEnvironment(
    'WPI_ENABLE_EMAIL_SIGNUP',
    defaultValue: true,
  );
}
