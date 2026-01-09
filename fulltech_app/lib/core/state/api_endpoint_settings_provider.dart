import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_endpoint_settings.dart';
import '../services/app_config.dart';

class ApiEndpointSettingsController extends StateNotifier<ApiEndpointSettings> {
  ApiEndpointSettingsController()
    : super(
        ApiEndpointSettings(
          backend: ApiBackend.cloud,
          localBaseUrl: AppConfig.normalizeApiBaseUrl(defaultLocalApiBaseUrl()),
        ),
      ) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final loaded = loadApiEndpointSettings(prefs);
    state = loaded;
    // Apply immediately to avoid baseUrl races (especially around login).
    applyApiEndpointSettings(loaded);
  }

  Future<void> setBackend(ApiBackend backend) async {
    state = state.copyWith(backend: backend);

    // Apply immediately to avoid a window where providers rebuild
    // before AppConfig has been updated.
    applyApiEndpointSettings(state);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      kApiBackendKey,
      backend == ApiBackend.local ? 'local' : 'cloud',
    );
  }

  Future<void> setLocalBaseUrl(String value) async {
    final normalized = value.trim().isEmpty
        ? AppConfig.normalizeApiBaseUrl(defaultLocalApiBaseUrl())
        : AppConfig.normalizeApiBaseUrl(value.trim());

    state = state.copyWith(localBaseUrl: normalized);

    // Apply immediately to avoid baseUrl races.
    applyApiEndpointSettings(state);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kApiLocalBaseUrlKey, normalized);
  }
}

final apiEndpointSettingsProvider =
    StateNotifierProvider<ApiEndpointSettingsController, ApiEndpointSettings>((
      ref,
    ) {
      return ApiEndpointSettingsController();
    });
