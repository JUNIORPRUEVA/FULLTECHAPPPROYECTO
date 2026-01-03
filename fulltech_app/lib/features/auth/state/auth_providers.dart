import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_client.dart';
import '../../../core/services/auth_api.dart';
import '../../../core/storage/local_db.dart';
import 'auth_controller.dart';
import 'auth_state.dart';

final localDbProvider = Provider<LocalDb>((ref) {
  throw UnimplementedError('localDbProvider must be overridden in ProviderScope');
});

final apiClientProvider = Provider<ApiClient>((ref) {
  throw UnimplementedError('apiClientProvider must be overridden in ProviderScope');
});

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(apiClientProvider).dio);
});

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    db: ref.watch(localDbProvider),
    api: ref.watch(authApiProvider),
  );
});

/// Provider to track if access has been revoked
final accessRevokedProvider = StateNotifierProvider<AccessRevokedNotifier, bool>((ref) {
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
