import '../../catalogo/models/categoria_producto.dart';
import '../../catalogo/models/producto.dart';

class PresupuestoCatalogState {
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  final List<CategoriaProducto> categorias;
  final List<Producto> productos;

  final String query;
  final String? selectedCategoriaId;
  final double? minPrice;
  final double? maxPrice;
  final String order;
  final String? productType;

  final int page;
  final int limit;
  final bool hasMore;

  const PresupuestoCatalogState({
    required this.isLoading,
    required this.isLoadingMore,
    required this.error,
    required this.categorias,
    required this.productos,
    required this.query,
    required this.selectedCategoriaId,
    required this.minPrice,
    required this.maxPrice,
    required this.order,
    required this.productType,
    required this.page,
    required this.limit,
    required this.hasMore,
  });

  factory PresupuestoCatalogState.initial() {
    return const PresupuestoCatalogState(
      isLoading: false,
      isLoadingMore: false,
      error: null,
      categorias: [],
      productos: [],
      query: '',
      selectedCategoriaId: null,
      minPrice: null,
      maxPrice: null,
      order: 'most_used',
      productType: null,
      page: 1,
      limit: 24,
      hasMore: true,
    );
  }

  PresupuestoCatalogState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
    List<CategoriaProducto>? categorias,
    List<Producto>? productos,
    String? query,
    String? selectedCategoriaId,
    double? minPrice,
    double? maxPrice,
    String? order,
    String? productType,
    int? page,
    int? limit,
    bool? hasMore,
  }) {
    return PresupuestoCatalogState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      categorias: categorias ?? this.categorias,
      productos: productos ?? this.productos,
      query: query ?? this.query,
      selectedCategoriaId: selectedCategoriaId ?? this.selectedCategoriaId,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      order: order ?? this.order,
      productType: productType ?? this.productType,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}
