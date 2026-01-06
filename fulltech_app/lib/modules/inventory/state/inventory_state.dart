import '../models/inventory_product.dart';
import '../models/inventory_summary.dart';

class InventoryProductsState {
  final bool isLoading;
  final String? error;
  final List<InventoryProduct> items;
  final int total;
  final int page;
  final int pageSize;
  final String search;
  final String? categoryId;
  final String? brand;
  final String? supplierId;
  final String status;
  final String sort;
  final InventorySummary? summary;
  final Set<String> knownBrands;

  const InventoryProductsState({
    required this.isLoading,
    required this.error,
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.search,
    required this.categoryId,
    required this.brand,
    required this.supplierId,
    required this.status,
    required this.sort,
    required this.summary,
    required this.knownBrands,
  });

  factory InventoryProductsState.initial() {
    return const InventoryProductsState(
      isLoading: false,
      error: null,
      items: [],
      total: 0,
      page: 1,
      pageSize: 25,
      search: '',
      categoryId: null,
      brand: null,
      supplierId: null,
      status: 'all',
      sort: 'updated',
      summary: null,
      knownBrands: {},
    );
  }

  InventoryProductsState copyWith({
    bool? isLoading,
    String? error,
    List<InventoryProduct>? items,
    int? total,
    int? page,
    int? pageSize,
    String? search,
    String? categoryId,
    String? brand,
    String? supplierId,
    String? status,
    String? sort,
    InventorySummary? summary,
    Set<String>? knownBrands,
    bool clearError = false,
  }) {
    return InventoryProductsState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      items: items ?? this.items,
      total: total ?? this.total,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      search: search ?? this.search,
      categoryId: categoryId ?? this.categoryId,
      brand: brand ?? this.brand,
      supplierId: supplierId ?? this.supplierId,
      status: status ?? this.status,
      sort: sort ?? this.sort,
      summary: summary ?? this.summary,
      knownBrands: knownBrands ?? this.knownBrands,
    );
  }
}
