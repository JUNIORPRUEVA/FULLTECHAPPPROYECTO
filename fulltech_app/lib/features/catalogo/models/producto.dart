import 'categoria_producto.dart';

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) {
    final v = value.trim();
    if (v.isEmpty) return 0;
    return double.tryParse(v.replaceAll(',', '.')) ?? 0;
  }
  return 0;
}

String _toString(dynamic value) {
  if (value == null) return '';
  return value.toString();
}

class Producto {
  final String id;
  final String nombre;
  final double precioCompra;
  final double precioVenta;
  final String imagenUrl;
  final String categoriaId;
  final CategoriaProducto? categoria;
  final int stock;
  final int minStock;
  final int maxStock;

  /// Brand identifier used by the Catalog UI.
  ///
  /// Backend currently stores this as a free-text brand in `Producto.brand`.
  /// We keep the name here for simplicity.
  final String? brandId;

  /// Supplier reference.
  ///
  /// Backend uses `supplier_id` (uuid). We store the id here.
  final String? supplier;
  final int searchCount;
  final bool isActive;

  const Producto({
    required this.id,
    required this.nombre,
    required this.precioCompra,
    required this.precioVenta,
    required this.imagenUrl,
    required this.categoriaId,
    required this.categoria,
    required this.stock,
    required this.minStock,
    required this.maxStock,
    required this.brandId,
    required this.supplier,
    required this.searchCount,
    required this.isActive,
  });

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) {
      final v = value.trim();
      if (v.isEmpty) return 0;
      final n = double.tryParse(v.replaceAll(',', '.'));
      if (n == null) return 0;
      return n.round();
    }
    return 0;
  }

  static String? _toNullableString(dynamic value) {
    if (value == null) return null;
    final s = value.toString();
    return s.trim().isEmpty ? null : s;
  }

  factory Producto.fromJson(Map<String, dynamic> json) {
    final stockRaw = json['stock'] ?? json['stock_qty'];
    final minRaw = json['minStock'] ?? json['min_stock'];
    final maxRaw = json['maxStock'] ?? json['max_stock'];

    final brandRaw = json.containsKey('brand_id')
        ? json['brand_id']
        : json['brand'];
    final supplierRaw = json.containsKey('supplier')
        ? json['supplier']
        : json['supplier_id'];

    return Producto(
      id: _toString(json['id']),
      nombre: _toString(json['nombre']),
      precioCompra: _toDouble(json['precio_compra']),
      precioVenta: _toDouble(json['precio_venta']),
      imagenUrl: _toString(json['imagen_url']),
      categoriaId: _toString(json['categoria_id']),
      categoria: json['categoria'] is Map<String, dynamic>
          ? CategoriaProducto.fromJson(
              json['categoria'] as Map<String, dynamic>,
            )
          : null,
      stock: _toInt(stockRaw),
      minStock: _toInt(minRaw),
      maxStock: _toInt(maxRaw),
      brandId: _toNullableString(brandRaw),
      supplier: _toNullableString(supplierRaw),
      searchCount: (json['search_count'] as num?)?.toInt() ?? 0,
      isActive: (json['is_active'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'precio_compra': precioCompra,
      'precio_venta': precioVenta,
      'imagen_url': imagenUrl,
      'categoria_id': categoriaId,
      'categoria': categoria?.toJson(),
      'stock': stock,
      'min_stock': minStock,
      'max_stock': maxStock,
      'brand_id': brandId,
      'supplier': supplier,
      'search_count': searchCount,
      'is_active': isActive,
    };
  }
}
