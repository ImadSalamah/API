/// Central place to manage API base URL.
class ApiConfig {
  /// Base URL for all API calls. Override with --dart-define API_BASE_URL.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  /// Helper to build a Uri using the base URL.
  static Uri uri(String path) => Uri.parse('$baseUrl$path');
}
