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
}
