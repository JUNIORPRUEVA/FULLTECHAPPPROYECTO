class AppConfig {
  AppConfig._();

  static String? _runtimeApiBaseUrlOverride;
  static String? _runtimeCrmApiBaseUrlOverride;

  /// Allows changing API base URL at runtime (e.g. from Settings).
  /// Pass null/empty to clear override and use compile-time env/defaults.
  static void setRuntimeApiBaseUrlOverride(String? baseUrl) {
    final v = (baseUrl ?? '').trim();
    _runtimeApiBaseUrlOverride = v.isEmpty ? null : normalizeApiBaseUrl(v);
  }

  /// Allows changing CRM API base URL at runtime.
  /// Pass null/empty to clear override.
  static void setRuntimeCrmApiBaseUrlOverride(String? baseUrl) {
    final v = (baseUrl ?? '').trim();
    _runtimeCrmApiBaseUrlOverride = v.isEmpty ? null : normalizeApiBaseUrl(v);
  }

  /// Configure by running Flutter with:
  /// `--dart-define=API_BASE_URL=http://localhost:3000/api`
  static const String _apiBaseUrlEnv = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get apiBaseUrl {
    final runtime = _runtimeApiBaseUrlOverride?.trim();
    if (runtime != null && runtime.isNotEmpty) return runtime;

    final v = _apiBaseUrlEnv.trim();
    if (v.isEmpty)
      return 'https://fulltechapp-fulltechapp.gcdndd.easypanel.host/api';
    return _normalizeApiBaseUrl(v);
  }

  /// Configure CRM only by running Flutter with:
  /// `--dart-define=CRM_API_BASE_URL=https://your-domain/api`
  static const String _crmApiBaseUrlEnv = String.fromEnvironment(
    'CRM_API_BASE_URL',
    defaultValue: '',
  );

  /// CRM-only API base URL.
  /// Defaults to the same backend as the rest of the app (`apiBaseUrl`) to
  /// prevent token/backend mismatches.
  static String get crmApiBaseUrl {
    final runtime = _runtimeCrmApiBaseUrlOverride?.trim();
    if (runtime != null && runtime.isNotEmpty) return runtime;

    final v = _crmApiBaseUrlEnv.trim();
    if (v.isNotEmpty) return _normalizeApiBaseUrl(v);

    return apiBaseUrl;
  }

  static String _normalizeApiBaseUrl(String raw) {
    var v = raw.trim();
    while (v.endsWith('/')) {
      v = v.substring(0, v.length - 1);
    }
    if (v.endsWith('/api')) return v;
    return '$v/api';
  }

  /// Normalizes an API base URL to end in `/api` and have no trailing slash.
  /// Public helper for UI/settings.
  static String normalizeApiBaseUrl(String raw) => _normalizeApiBaseUrl(raw);

  static const appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '0.1.0',
  );

  // =============================================================
  // Evolution (direct send from Flutter) - for debugging/diagnosis
  // WARNING: Shipping API keys in a client app is insecure. Use only
  // for controlled environments.
  // =============================================================
  static const bool crmSendDirectEvolution = bool.fromEnvironment(
    'CRM_SEND_DIRECT_EVOLUTION',
    defaultValue: false,
  );

  static const String evolutionApiBaseUrl = String.fromEnvironment(
    'EVOLUTION_API_URL',
    defaultValue: '',
  );

  static const String evolutionApiKey = String.fromEnvironment(
    'EVOLUTION_API_KEY',
    defaultValue: '',
  );

  static const String evolutionInstance = String.fromEnvironment(
    'EVOLUTION_API_INSTANCE_NAME',
    defaultValue: '',
  );

  static const String evolutionDefaultCountryCode = String.fromEnvironment(
    'EVOLUTION_DEFAULT_COUNTRY_CODE',
    defaultValue: '1',
  );
}
