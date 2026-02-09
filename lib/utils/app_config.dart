/// Global app configuration values.
class AppConfig {
  AppConfig._();

  /// Base URL for backend API.
  ///
  /// Override at build time with:
  //  --dart-define=API_BASE_URL=https://api.wpicenter.com
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL',
      defaultValue: 'https://api.wpicenter.com');

  /// Toggle to enable the new WPI flow for A/B comparison.
  /// Usage:
  ///   --dart-define=USE_NEW_WPI_FLOW=true
  static const bool useNewWpiFlow =
      bool.fromEnvironment('USE_NEW_WPI_FLOW', defaultValue: false);

  /// Google Sign-In client ID (required for web).
  /// Usage:
  ///   --dart-define=GOOGLE_CLIENT_ID=YOUR_WEB_CLIENT_ID
  static const String googleClientId =
      String.fromEnvironment('GOOGLE_CLIENT_ID', defaultValue: '');
}
