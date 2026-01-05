import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/usuarios/state/users_providers.dart';
import '../../../features/auth/state/auth_providers.dart';
import '../../../features/auth/state/auth_state.dart';

import '../data/datasources/rules_remote_datasource.dart';
import '../data/models/rules_content.dart';
import '../data/models/rules_page.dart';
import '../data/models/rules_query.dart';
import '../data/repositories/rules_repository.dart';

final rulesRemoteDataSourceProvider = Provider<RulesRemoteDataSource>((ref) {
  return RulesRemoteDataSource(ref.watch(apiClientProvider).dio);
});

final rulesRepositoryProvider = Provider<RulesRepository>((ref) {
  return RulesRepository(ref.watch(rulesRemoteDataSourceProvider));
});

/// Reuse the app's admin detection (admin/administrador).
final rulesIsAdminProvider = Provider<bool>((ref) => ref.watch(isAdminProvider));

/// Current authenticated role string (null if not logged in).
final currentUserRoleProvider = Provider<String?>((ref) {
  final auth = ref.watch(authControllerProvider);
  if (auth is! AuthAuthenticated) return null;
  return auth.user.role;
});

/// Used to force refresh after create/update/delete.
final rulesRefreshTickProvider = StateProvider<int>((ref) => 0);

final rulesListProvider = FutureProvider.family<RulesPage, RulesQuery>((ref, query) async {
  ref.watch(rulesRefreshTickProvider);
  final repo = ref.watch(rulesRepositoryProvider);
  return repo.list(query);
});

final rulesItemProvider = FutureProvider.family<RulesContent, String>((ref, id) async {
  ref.watch(rulesRefreshTickProvider);
  return ref.watch(rulesRepositoryProvider).get(id);
});

void bumpRulesRefresh(WidgetRef ref) {
  ref.read(rulesRefreshTickProvider.notifier).state++;
}
