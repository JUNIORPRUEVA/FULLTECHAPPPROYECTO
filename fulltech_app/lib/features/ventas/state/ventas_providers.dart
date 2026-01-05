import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/state/auth_providers.dart';
import '../data/sales_api.dart';
import '../data/sales_repository.dart';

final salesApiProvider = Provider<SalesApi>((ref) {
  final dio = ref.watch(apiClientProvider).dio;
  return SalesApi(dio);
});

final salesRepositoryProvider = Provider<SalesRepository>((ref) {
  final api = ref.watch(salesApiProvider);
  final db = ref.watch(localDbProvider);
  return SalesRepository(api: api, db: db);
});
