import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/state/auth_providers.dart';
import '../data/pos_api.dart';
import '../data/pos_repository.dart';
import 'pos_tpv_controller.dart';

final posApiProvider = Provider<PosApi>((ref) {
  final dio = ref.watch(apiClientProvider).dio;
  return PosApi(dio);
});

final posRepositoryProvider = Provider<PosRepository>((ref) {
  final api = ref.watch(posApiProvider);
  final db = ref.watch(localDbProvider);
  return PosRepository(api: api, db: db);
});

final posTpvControllerProvider = StateNotifierProvider<PosTpvController, PosTpvState>((ref) {
  final repo = ref.watch(posRepositoryProvider);
  return PosTpvController(repo: repo);
});
