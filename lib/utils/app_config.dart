/// Global app configuration values.
class AppConfig {
  AppConfig._();

  /// Base URL for backend API.
  ///
  /// Override at build time with:
  //  --dart-define=API_BASE_URL=https://api.wpicenter.com
  static const String apiBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: 'https://api.wpicenter.com');
}
