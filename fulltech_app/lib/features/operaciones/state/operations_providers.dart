import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/dio_provider.dart';
import '../../auth/state/auth_providers.dart';
import '../data/operations_api.dart';
import '../data/operations_repository.dart';
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
