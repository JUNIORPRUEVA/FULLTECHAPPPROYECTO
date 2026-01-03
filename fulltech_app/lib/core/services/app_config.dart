class AppConfig {
  AppConfig._();

  /// Configure by running Flutter with:
  /// `--dart-define=API_BASE_URL=http://localhost:3000/api`
  static const String _apiBaseUrlEnv = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get apiBaseUrl {
    final v = _apiBaseUrlEnv.trim();
    if (v.isEmpty) return 'http://localhost:3000/api';
    return v;
  }

  static const appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '0.1.0',
  );
}
