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
    required this.searchCount,
    required this.isActive,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
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
      'search_count': searchCount,
      'is_active': isActive,
    };
  }
}
