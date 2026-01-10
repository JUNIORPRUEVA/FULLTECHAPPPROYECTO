import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/state/auth_providers.dart';
import '../data/catalog_api.dart';
import '../../../modules/inventory/state/inventory_providers.dart';
import 'catalog_controller.dart';
import 'catalog_state.dart';

final catalogApiProvider = Provider<CatalogApi>((ref) {
  return CatalogApi(ref.watch(apiClientProvider).dio);
});

final catalogControllerProvider =
    StateNotifierProvider<CatalogController, CatalogState>((ref) {
      return CatalogController(
        api: ref.watch(catalogApiProvider),
        inventory: ref.watch(inventoryRepositoryProvider),
        db: ref.watch(localDbProvider),
      );
    });
