import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/debouncer.dart';
import '../data/inventory_repository.dart';
import 'inventory_state.dart';

class InventoryProductsController extends StateNotifier<InventoryProductsState> {
  InventoryProductsController({required this.repo})
      : _debouncer = Debouncer(delay: const Duration(milliseconds: 450)),
        super(InventoryProductsState.initial());

  final InventoryRepository repo;
  final Debouncer _debouncer;

  Future<void> bootstrap() async {
    if (state.items.isNotEmpty) return;
    await load();
  }

  Future<void> load({bool keepPage = true}) async {
    final nextPage = keepPage ? state.page : 1;
    state = state.copyWith(isLoading: true, clearError: true, page: nextPage);
    try {
      final res = await repo.listProducts(
        search: state.search,
        categoryId: state.categoryId,
        brand: state.brand,
        supplierId: state.supplierId,
        status: state.status,
        sort: state.sort,
        page: nextPage,
        pageSize: state.pageSize,
      );

      final brands = <String>{...state.knownBrands};
      for (final p in res.items) {
        final b = (p.brand ?? '').trim();
        if (b.isNotEmpty) brands.add(b);
      }

      state = state.copyWith(
        isLoading: false,
        items: res.items,
        total: res.total,
        page: res.page,
        pageSize: res.pageSize,
        summary: res.summary,
        knownBrands: brands,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setSearchDebounced(String v) {
    state = state.copyWith(search: v);
    _debouncer.run(() {
      load(keepPage: false);
    });
  }

  void setCategory(String? id) {
    state = state.copyWith(categoryId: id);
    load(keepPage: false);
  }

  void setBrand(String? v) {
    final trimmed = (v ?? '').trim();
    state = state.copyWith(brand: trimmed.isEmpty ? null : trimmed);
    load(keepPage: false);
  }

  void setSupplier(String? id) {
    state = state.copyWith(supplierId: id);
    load(keepPage: false);
  }

  void setStatus(String v) {
    state = state.copyWith(status: v);
    load(keepPage: false);
  }

  void setSort(String v) {
    state = state.copyWith(sort: v);
    load(keepPage: false);
  }

  void setPage(int page) {
    state = state.copyWith(page: page);
    load(keepPage: true);
  }

  void setPageSize(int size) {
    state = state.copyWith(pageSize: size, page: 1);
    load(keepPage: true);
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }
}
