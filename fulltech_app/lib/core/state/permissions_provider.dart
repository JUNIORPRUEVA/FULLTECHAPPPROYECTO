import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../features/auth/state/auth_providers.dart';

class PermissionsState {
  final Set<String> permissions;

  const PermissionsState(this.permissions);

  bool has(String code) => permissions.contains('*') || permissions.contains(code);
}

class PermissionsController extends StateNotifier<AsyncValue<PermissionsState>> {
  PermissionsController(this._ref) : super(const AsyncValue.loading());

  final Ref _ref;

  Future<void> load() async {
    try {
      final dio = _ref.read(apiClientProvider).dio;
      final res = await dio.get(
        '/settings/permissions/me',
        options: Options(extra: {'offlineCache': false}),
      );
      final data = res.data as Map<String, dynamic>;
      final raw = (data['permissions'] as List?)?.cast<dynamic>() ?? const [];
      final perms = raw.map((e) => e.toString()).toSet();
      state = AsyncValue.data(PermissionsState(perms));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void clear() {
    state = const AsyncValue.data(PermissionsState(<String>{}));
  }
}

final permissionsProvider = StateNotifierProvider<PermissionsController, AsyncValue<PermissionsState>>(
  (ref) => PermissionsController(ref),
);
