import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/dio_provider.dart';
import '../../auth/state/auth_providers.dart';
import '../../usuarios/models/registered_user.dart';
import '../../usuarios/state/users_providers.dart';
import '../data/operations_api.dart';
import '../data/operations_repository.dart';
import '../models/operations_models.dart';
import 'operations_jobs_controller.dart';
import 'operations_jobs_state.dart';

final operationsApiProvider = Provider<OperationsApi>((ref) {
  return OperationsApi(ref.watch(dioProvider));
});

final operationsRepositoryProvider = Provider<OperationsRepository>((ref) {
  return OperationsRepository(
    api: ref.watch(operationsApiProvider),
    db: ref.watch(localDbProvider),
  );
});

final operationsJobsControllerProvider = StateNotifierProvider<OperationsJobsController, OperationsJobsState>((ref) {
  return OperationsJobsController(
    repo: ref.watch(operationsRepositoryProvider),
    read: ref.read,
  );
});

final operationsJobDetailProvider = FutureProvider.family<OperationsJob, String>((
  ref,
  jobId,
) async {
  final repo = ref.watch(operationsRepositoryProvider);
  final data = await repo.getJobDetailFromServer(jobId: jobId);
  return OperationsJob.fromServerJson(data);
});

final operationsJobHistoryProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((
  ref,
  jobId,
) async {
  final repo = ref.watch(operationsRepositoryProvider);
  return repo.listJobHistory(jobId: jobId);
});

final operationsTechniciansProvider = FutureProvider<List<RegisteredUserSummary>>((
  ref,
) async {
  final api = ref.watch(usersApiProvider);

  Future<List<RegisteredUserSummary>> listByRole(String rol) async {
    final page = await api.listUsers(page: 1, pageSize: 200, rol: rol);
    return page.items;
  }

  final pages = await Future.wait([
    listByRole('tecnico'),
    listByRole('tecnico_fijo'),
    listByRole('contratista'),
  ]);

  final byId = <String, RegisteredUserSummary>{};
  for (final list in pages) {
    for (final u in list) {
      byId[u.id] = u;
    }
  }
  final out = byId.values.toList(growable: false);
  out.sort((a, b) => a.nombreCompleto.compareTo(b.nombreCompleto));
  return out;
});
