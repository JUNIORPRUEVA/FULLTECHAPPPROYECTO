import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_config.dart';

enum ApiBackend { cloud, local }

class ApiEndpointSettings {
  final ApiBackend backend;
  final String localBaseUrl;

  const ApiEndpointSettings({
    required this.backend,
    required this.localBaseUrl,
  });

  ApiEndpointSettings copyWith({ApiBackend? backend, String? localBaseUrl}) {
    return ApiEndpointSettings(
      backend: backend ?? this.backend,
      localBaseUrl: localBaseUrl ?? this.localBaseUrl,
    );
  }
}

const kApiBackendKey = 'settings.api.backend';
const kApiLocalBaseUrlKey = 'settings.api.localBaseUrl';

String defaultLocalApiBaseUrl() {
  // Android emulator can't reach host via localhost.
  // 10.0.2.2 is the special alias to the host loopback.
  if (kIsWeb) return 'http://localhost:3000/api';

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return 'http://10.0.2.2:3000/api';
    default:
      return 'http://localhost:3000/api';
  }
}

ApiEndpointSettings loadApiEndpointSettings(SharedPreferences prefs) {
  final rawBackend = (prefs.getString(kApiBackendKey) ?? '').trim();
  final backend = rawBackend == 'local' ? ApiBackend.local : ApiBackend.cloud;

  final localBaseUrlRaw = (prefs.getString(kApiLocalBaseUrlKey) ?? '').trim();
  final localBaseUrl = localBaseUrlRaw.isNotEmpty
      ? AppConfig.normalizeApiBaseUrl(localBaseUrlRaw)
      : AppConfig.normalizeApiBaseUrl(defaultLocalApiBaseUrl());

  return ApiEndpointSettings(backend: backend, localBaseUrl: localBaseUrl);
}

void applyApiEndpointSettings(ApiEndpointSettings settings) {
  // Safety net: never allow local overrides in non-debug builds.
  if (!kDebugMode) {
    AppConfig.setRuntimeApiBaseUrlOverride(null);
    AppConfig.setRuntimeCrmApiBaseUrlOverride(null);
    return;
  }

  if (settings.backend == ApiBackend.local) {
    AppConfig.setRuntimeApiBaseUrlOverride(settings.localBaseUrl);
    AppConfig.setRuntimeCrmApiBaseUrlOverride(settings.localBaseUrl);
  } else {
    AppConfig.setRuntimeApiBaseUrlOverride(null);
    AppConfig.setRuntimeCrmApiBaseUrlOverride(null);
  }
}
