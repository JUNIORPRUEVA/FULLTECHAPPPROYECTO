import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_client.dart';
import '../../../core/services/app_config.dart';
import '../../../core/services/auth_api.dart';
import '../../../core/storage/local_db.dart';
import '../../../core/state/api_endpoint_settings_provider.dart';
import 'auth_controller.dart';
import 'auth_state.dart';

final localDbProvider = Provider<LocalDb>((ref) {
  throw UnimplementedError(
    'localDbProvider must be overridden in ProviderScope',
  );
});

final apiClientProvider = Provider<ApiClient>((ref) {
  // Rebuild client when the API endpoint setting changes.
  ref.watch(apiEndpointSettingsProvider);
  final db = ref.watch(localDbProvider);
  return ApiClient.forBaseUrl(db, AppConfig.apiBaseUrl);
});

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(apiClientProvider).dio);
});

/// CRITICAL: Auth controller must NOT rebuild when API endpoint changes.
/// Using KeepAliveLink to prevent disposal during configuration changes.
/// This ensures the user session persists even when switching servers in debug mode.
final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    // Keep this provider alive to prevent disposal during rebuilds
    final keepAlive = ref.keepAlive();
    
    // Read (not watch) localDb - it's stable and won't cause rebuilds
    final db = ref.read(localDbProvider);
    
    // Create a getter function that can fetch the current API dynamically
    // This allows the controller to use the current API endpoint without
    // causing the controller itself to rebuild when endpoints change
    AuthApi getAuthApi() {
      final apiClient = ref.read(apiClientProvider);
      return AuthApi(apiClient.dio);
    }
    
    return AuthController(
      db: db,
      getAuthApi: getAuthApi,
      onDispose: () {
        // Cancel keep-alive when explicitly disposing
        keepAlive.close();
      },
    );
  },
);

/// Provider to track if access has been revoked
final accessRevokedProvider =
    StateNotifierProvider<AccessRevokedNotifier, bool>((ref) {
      return AccessRevokedNotifier();
    });

class AccessRevokedNotifier extends StateNotifier<bool> {
  AccessRevokedNotifier() : super(false);

  void revoke() {
    state = true;
  }

  void reset() {
    state = false;
  }
}
