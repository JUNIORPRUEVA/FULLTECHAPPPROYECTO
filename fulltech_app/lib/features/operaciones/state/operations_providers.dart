import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/dio_provider.dart';
import '../../auth/state/auth_providers.dart';
import '../../usuarios/models/registered_user.dart';
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

final operationsJobsControllerProvider =
    StateNotifierProvider<OperationsJobsController, OperationsJobsState>((ref) {
      return OperationsJobsController(
        repo: ref.watch(operationsRepositoryProvider),
        read: ref.read,
      );
    });

final operationsJobDetailProvider =
    FutureProvider.family<OperationsJob, String>((ref, jobId) async {
      final repo = ref.watch(operationsRepositoryProvider);
      final data = await repo.getJobDetailFromServer(jobId: jobId);
      return OperationsJob.fromServerJson(data);
    });

final operationsJobHistoryProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      jobId,
    ) async {
      final repo = ref.watch(operationsRepositoryProvider);
      return repo.listJobHistory(jobId: jobId);
    });

final operationsWarrantyTicketsProvider =
    FutureProvider.family<List<OperationsWarrantyTicket>, String>((
      ref,
      jobId,
    ) async {
      final repo = ref.watch(operationsRepositoryProvider);
      return repo.listLocalWarrantyTickets(jobId: jobId);
    });

final operationsTechniciansProvider =
    FutureProvider<List<RegisteredUserSummary>>((ref) async {
      final dio = ref.watch(dioProvider);

      final res = await dio.get('/operations/technicians');
      final data = res.data as Map<String, dynamic>;
      final items = (data['items'] as List<dynamic>? ?? const <dynamic>[])
          .cast<Map<String, dynamic>>()
          .map(RegisteredUserSummary.fromJson)
          .toList(growable: false);

      final allowed = <String>{'tecnico', 'tecnico_fijo', 'contratista'};
      final out = items
          .where((u) => allowed.contains(u.rol.toLowerCase().trim()))
          .toList(growable: false);
      out.sort((a, b) => a.nombreCompleto.compareTo(b.nombreCompleto));
      return out;
    });
