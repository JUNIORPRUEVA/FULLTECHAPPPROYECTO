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
    return _normalizeApiBaseUrl(v);
  }

  /// Configure CRM only by running Flutter with:
  /// `--dart-define=CRM_API_BASE_URL=https://your-domain/api`
  static const String _crmApiBaseUrlEnv = String.fromEnvironment(
    'CRM_API_BASE_URL',
    defaultValue: '',
  );

  /// CRM-only API base URL.
  /// Default points to the deployed backend in EasyPanel (cloud).
  static String get crmApiBaseUrl {
    final v = _crmApiBaseUrlEnv.trim();
    if (v.isNotEmpty) return _normalizeApiBaseUrl(v);
    return 'https://fulltechapp-fulltechapp.gcdndd.easypanel.host/api';
  }

  static String _normalizeApiBaseUrl(String raw) {
    var v = raw.trim();
    while (v.endsWith('/')) {
      v = v.substring(0, v.length - 1);
    }
    if (v.endsWith('/api')) return v;
    return '$v/api';
  }

  static const appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '0.1.0',
  );
}
