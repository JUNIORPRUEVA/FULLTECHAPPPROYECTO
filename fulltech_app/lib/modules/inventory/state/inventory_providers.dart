import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/state/auth_providers.dart';
import '../../../features/catalogo/data/catalog_api.dart';
import '../../../features/catalogo/models/categoria_producto.dart';
import '../data/inventory_api.dart';
import '../data/inventory_repository.dart';
import 'inventory_products_controller.dart';
import 'inventory_state.dart';

final inventoryApiProvider = Provider<InventoryApi>((ref) {
  final dio = ref.watch(apiClientProvider).dio;
  return InventoryApi(dio);
});

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository(api: ref.watch(inventoryApiProvider));
});

final inventoryProductsControllerProvider =
    StateNotifierProvider<InventoryProductsController, InventoryProductsState>((ref) {
  final repo = ref.watch(inventoryRepositoryProvider);
  final controller = InventoryProductsController(repo: repo);
  Future.microtask(controller.bootstrap);
  return controller;
});

final inventorySelectedProductIdProvider = StateProvider<String?>((ref) => null);

final inventoryCatalogApiProvider = Provider<CatalogApi>((ref) {
  return CatalogApi(ref.watch(apiClientProvider).dio);
});

final inventoryCategoriesProvider = FutureProvider<List<CategoriaProducto>>((ref) async {
  final api = ref.watch(inventoryCatalogApiProvider);
  return api.listCategorias();
});

final inventorySuppliersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(inventoryRepositoryProvider);
  return repo.listSuppliers();
});
