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

class InventoryProduct {
  final String id;
  final String nombre;
  final String categoriaId;
  final String categoriaNombre;
  final String? brand;
  final String? supplierId;
  final String? supplierName;
  final double stockQty;
  final double minStock;
  final double maxStock;
  final double precioCompra;
  final double precioVenta;
  final DateTime updatedAt;

  const InventoryProduct({
    required this.id,
    required this.nombre,
    required this.categoriaId,
    required this.categoriaNombre,
    required this.brand,
    required this.supplierId,
    required this.supplierName,
    required this.stockQty,
    required this.minStock,
    required this.maxStock,
    required this.precioCompra,
    required this.precioVenta,
    required this.updatedAt,
  });

  factory InventoryProduct.fromJson(Map<String, dynamic> json) {
    return InventoryProduct(
      id: _toString(json['id']),
      nombre: _toString(json['nombre']),
      categoriaId: _toString(json['categoria_id']),
      categoriaNombre: _toString(json['categoria_nombre']),
      brand: (json['brand'] as String?)?.trim().isEmpty == true
          ? null
          : (json['brand'] as String?),
      supplierId: (json['supplier_id'] as String?)?.trim().isEmpty == true
          ? null
          : (json['supplier_id'] as String?),
      supplierName: (json['supplier_name'] as String?)?.trim().isEmpty == true
          ? null
          : (json['supplier_name'] as String?),
      stockQty: _toDouble(json['stock_qty']),
      minStock: _toDouble(json['min_stock']),
      maxStock: _toDouble(json['max_stock']),
      precioCompra: _toDouble(json['precio_compra']),
      precioVenta: _toDouble(json['precio_venta']),
      updatedAt: DateTime.tryParse(_toString(json['updated_at'])) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  InventoryProduct copyWith({
    String? brand,
    String? supplierId,
    String? supplierName,
    double? stockQty,
    double? minStock,
    double? maxStock,
    DateTime? updatedAt,
  }) {
    return InventoryProduct(
      id: id,
      nombre: nombre,
      categoriaId: categoriaId,
      categoriaNombre: categoriaNombre,
      brand: brand ?? this.brand,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      stockQty: stockQty ?? this.stockQty,
      minStock: minStock ?? this.minStock,
      maxStock: maxStock ?? this.maxStock,
      precioCompra: precioCompra,
      precioVenta: precioVenta,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
