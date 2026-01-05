import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../catalogo/data/catalog_api.dart';
import '../../catalogo/state/catalog_providers.dart';
import 'presupuesto_catalog_state.dart';

final presupuestoCatalogControllerProvider =
    StateNotifierProvider<
      PresupuestoCatalogController,
      PresupuestoCatalogState
    >((ref) {
      return PresupuestoCatalogController(api: ref.watch(catalogApiProvider));
    });

class PresupuestoCatalogController
    extends StateNotifier<PresupuestoCatalogState> {
  final CatalogApi _api;
  Timer? _debounce;

  PresupuestoCatalogController({required CatalogApi api})
    : _api = api,
      super(PresupuestoCatalogState.initial());

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> bootstrap() async {
    await Future.wait([loadCategorias(), refreshProductos()]);
  }

  Future<void> loadCategorias() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final cats = await _api.listCategorias(includeInactive: true);
      state = state.copyWith(
        isLoading: false,
        categorias: cats,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setQuery(String value) {
    state = state.copyWith(query: value, clearError: true);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      unawaited(refreshProductos());
    });
  }

  void setCategoria(String? categoriaId) {
    state = state.copyWith(selectedCategoriaId: categoriaId, clearError: true);
    unawaited(refreshProductos());
  }

  void setFilters({
    double? minPrice,
    double? maxPrice,
    String? order,
    String? productType,
  }) {
    state = state.copyWith(
      minPrice: minPrice,
      maxPrice: maxPrice,
      order: order ?? state.order,
      productType: productType,
      clearError: true,
    );
    unawaited(refreshProductos());
  }

  Future<void> refreshProductos() async {
    state = state.copyWith(
      isLoading: true,
      isLoadingMore: false,
      page: 1,
      hasMore: true,
      clearError: true,
      productos: [],
    );
    try {
      final items = await _api.listProductos(
        q: state.query,
        categoryId: state.selectedCategoriaId,
        page: 1,
        limit: state.limit,
        order: state.order,
        minPrice: state.minPrice,
        maxPrice: state.maxPrice,
        productType: state.productType,
        includeInactive: false,
      );

      state = state.copyWith(
        isLoading: false,
        productos: items,
        page: 1,
        hasMore: items.length >= state.limit,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    final nextPage = state.page + 1;
    state = state.copyWith(isLoadingMore: true, clearError: true);

    try {
      final items = await _api.listProductos(
        q: state.query,
        categoryId: state.selectedCategoriaId,
        page: nextPage,
        limit: state.limit,
        order: state.order,
        minPrice: state.minPrice,
        maxPrice: state.maxPrice,
        productType: state.productType,
        includeInactive: false,
      );

      state = state.copyWith(
        isLoadingMore: false,
        productos: [...state.productos, ...items],
        page: nextPage,
        hasMore: items.length >= state.limit,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }
}
