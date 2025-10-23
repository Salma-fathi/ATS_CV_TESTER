class AppConfig {
  static const String appName = 'ATS CV Tester';
  static const String appVersion = '1.0.0';

  // Environment-based configuration
  static const String _devBaseUrl = 'http://localhost:5000/api';
  static const String _prodBaseUrl = 'https://your-production-api.com';

  static String get baseUrl {
    const environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'dev');
    return environment == 'prod' ? _prodBaseUrl : _devBaseUrl;
  }

  // API endpoints
  static const String analyzeEndpoint = '/analyze';
  static const String uploadEndpoint = '/upload';

  // File constraints
  static const int maxFileSizeMB = 10;
  static const List<String> allowedFileTypes = ['pdf', 'doc', 'docx'];

  // UI constants
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;

  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);
}
