import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_client.dart';
import '../../../core/services/app_config.dart';
import '../../../core/services/auth_api.dart';
import '../../../core/storage/local_db.dart';
import '../../../core/state/api_endpoint_settings_provider.dart';
import '../../../core/services/api_endpoint_settings.dart';
import 'auth_controller.dart';
import 'auth_state.dart';

final localDbProvider = Provider<LocalDb>((ref) {
  throw UnimplementedError(
    'localDbProvider must be overridden in ProviderScope',
  );
});

final apiClientProvider = Provider<ApiClient>((ref) {
  // Rebuild client when the API endpoint setting changes.
  final settings = ref.watch(apiEndpointSettingsProvider);
  final db = ref.watch(localDbProvider);
  final baseUrl = effectiveApiBaseUrl(settings);
  return ApiClient.forBaseUrl(db, baseUrl);
});

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(apiClientProvider).dio);
});

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(
      db: ref.watch(localDbProvider),
      // IMPORTANT: do NOT watch authApiProvider here.
      // Watching it would rebuild AuthController on every endpoint change,
      // resetting state and forcing re-login.
      getApi: () => ref.read(authApiProvider),
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
