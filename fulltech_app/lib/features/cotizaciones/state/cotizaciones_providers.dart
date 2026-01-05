import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fulltech_app/features/auth/state/auth_providers.dart';
import 'package:fulltech_app/features/cotizaciones/data/quotation_repository.dart';
import 'package:fulltech_app/features/presupuesto/data/quotation_api.dart';

final quotationApiProvider = Provider<QuotationApi>((ref) {
  final dio = ref.watch(apiClientProvider).dio;
  return QuotationApi(dio);
});

final quotationRepositoryProvider = Provider<QuotationRepository>((ref) {
  final api = ref.watch(quotationApiProvider);
  final db = ref.watch(localDbProvider);
  return QuotationRepository(api: api, db: db);
});
