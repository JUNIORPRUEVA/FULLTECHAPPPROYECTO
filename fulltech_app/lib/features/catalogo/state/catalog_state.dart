import '../models/categoria_producto.dart';
import '../models/producto.dart';

class CatalogState {
  final bool isLoading;
  final String? error;

  final bool isOnline;

  final List<CategoriaProducto> categorias;
  final List<Producto> productos;

  final String query;
  final String? selectedCategoriaId;
  final bool includeInactive;

  const CatalogState({
    required this.isLoading,
    required this.error,
    required this.isOnline,
    required this.categorias,
    required this.productos,
    required this.query,
    required this.selectedCategoriaId,
    required this.includeInactive,
  });

  factory CatalogState.initial() {
    return const CatalogState(
      isLoading: false,
      error: null,
      isOnline: true,
      categorias: [],
      productos: [],
      query: '',
      selectedCategoriaId: null,
      includeInactive: false,
    );
  }

  CatalogState copyWith({
    bool? isLoading,
    String? error,
    bool? isOnline,
    List<CategoriaProducto>? categorias,
    List<Producto>? productos,
    String? query,
    String? selectedCategoriaId,
    bool? includeInactive,
  }) {
    return CatalogState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isOnline: isOnline ?? this.isOnline,
      categorias: categorias ?? this.categorias,
      productos: productos ?? this.productos,
      query: query ?? this.query,
      selectedCategoriaId: selectedCategoriaId ?? this.selectedCategoriaId,
      includeInactive: includeInactive ?? this.includeInactive,
    );
  }
}
