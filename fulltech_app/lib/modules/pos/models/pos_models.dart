import 'package:intl/intl.dart';

final _money = NumberFormat.currency(symbol: r'$', decimalDigits: 2);

String money(num? v) => _money.format((v ?? 0).toDouble());

double _asDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

class PosCategory {
  final String id;
  final String nombre;

  PosCategory({required this.id, required this.nombre});

  factory PosCategory.fromJson(Map<String, dynamic> json) {
    return PosCategory(
      id: json['id'] as String,
      nombre: (json['nombre'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
      };
}

class PosSupplier {
  final String id;
  final String name;
  final String? phone;
  final String? rnc;
  final String? email;
  final String? address;

  PosSupplier({
    required this.id,
    required this.name,
    required this.phone,
    required this.rnc,
    required this.email,
    required this.address,
  });

  factory PosSupplier.fromJson(Map<String, dynamic> json) {
    String? cleanNullable(dynamic v) {
      final s = (v ?? '').toString().trim();
      return s.isEmpty ? null : s;
    }

    return PosSupplier(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      phone: cleanNullable(json['phone']),
      rnc: cleanNullable(json['rnc']),
      email: cleanNullable(json['email']),
      address: cleanNullable(json['address']),
    );
  }
}

class PosProduct {
  final String id;
  final String nombre;
  final double precioVenta;
  final double costPrice;
  final double stockQty;
  final double minStock;
  final double maxStock;
  final bool allowNegativeStock;
  final bool lowStock;
  final double suggestedReorderQty;
  final PosCategory? categoria;
  final String? imagenUrl;

  PosProduct({
    required this.id,
    required this.nombre,
    required this.precioVenta,
    required this.costPrice,
    required this.stockQty,
    required this.minStock,
    required this.maxStock,
    required this.allowNegativeStock,
    required this.lowStock,
    required this.suggestedReorderQty,
    required this.categoria,
    required this.imagenUrl,
  });

  factory PosProduct.fromJson(Map<String, dynamic> json) {
    return PosProduct(
      id: json['id'] as String,
      nombre: (json['nombre'] ?? '').toString(),
      precioVenta: _asDouble(json['precio_venta']),
      costPrice: _asDouble(json['cost_price']),
      stockQty: _asDouble(json['stock_qty']),
      minStock: _asDouble(json['min_stock']),
      maxStock: _asDouble(json['max_stock']),
      allowNegativeStock: json['allow_negative_stock'] == true,
      lowStock: json['low_stock'] == true,
      suggestedReorderQty: _asDouble(json['suggested_reorder_qty']),
      categoria: json['categoria'] is Map<String, dynamic>
          ? PosCategory.fromJson((json['categoria'] as Map).cast<String, dynamic>())
          : null,
      imagenUrl: (json['imagen_url'] ?? '').toString().trim().isEmpty
          ? null
          : (json['imagen_url'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'precio_venta': precioVenta,
        'cost_price': costPrice,
        'stock_qty': stockQty,
        'min_stock': minStock,
        'max_stock': maxStock,
        'allow_negative_stock': allowNegativeStock,
        'low_stock': lowStock,
        'suggested_reorder_qty': suggestedReorderQty,
        'categoria': categoria?.toJson(),
        'imagen_url': imagenUrl,
      };
}

class PosSaleItemDraft {
  final PosProduct product;
  final double qty;
  final double unitPrice;
  final double discountAmount;

  const PosSaleItemDraft({
    required this.product,
    required this.qty,
    required this.unitPrice,
    required this.discountAmount,
  });

  PosSaleItemDraft copyWith({
    double? qty,
    double? unitPrice,
    double? discountAmount,
  }) {
    return PosSaleItemDraft(
      product: product,
      qty: qty ?? this.qty,
      unitPrice: unitPrice ?? this.unitPrice,
      discountAmount: discountAmount ?? this.discountAmount,
    );
  }

  double get lineSubtotal => (qty * unitPrice) - discountAmount;
}

class PosSaleItem {
  final String id;
  final String productId;
  final String productName;
  final double qty;
  final double unitPrice;
  final double discountAmount;
  final double itbisAmount;
  final double lineTotal;

  PosSaleItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.qty,
    required this.unitPrice,
    required this.discountAmount,
    required this.itbisAmount,
    required this.lineTotal,
  });

  factory PosSaleItem.fromJson(Map<String, dynamic> json) {
    return PosSaleItem(
      id: json['id'] as String,
      productId: (json['product_id'] ?? '').toString(),
      productName: (json['product_name'] ?? '').toString(),
      qty: _asDouble(json['qty']),
      unitPrice: _asDouble(json['unit_price']),
      discountAmount: _asDouble(json['discount_amount']),
      itbisAmount: _asDouble(json['itbis_amount']),
      lineTotal: _asDouble(json['line_total']),
    );
  }
}

class PosSale {
  final String id;
  final String invoiceNo;
  final String invoiceType;
  final String? ncf;
  final String? customerId;
  final String? customerName;
  final String? customerRnc;
  final String status;
  final String? paymentMethod;
  final double subtotal;
  final double discountTotal;
  final double itbisTotal;
  final double total;
  final double paidAmount;
  final double changeAmount;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PosSaleItem> items;

  PosSale({
    required this.id,
    required this.invoiceNo,
    required this.invoiceType,
    required this.ncf,
    required this.customerId,
    required this.customerName,
    required this.customerRnc,
    required this.status,
    required this.paymentMethod,
    required this.subtotal,
    required this.discountTotal,
    required this.itbisTotal,
    required this.total,
    required this.paidAmount,
    required this.changeAmount,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
  });

  factory PosSale.fromJson(Map<String, dynamic> json) {
    final itemsJson = (json['items'] as List?)?.cast<Map>() ?? const [];

    return PosSale(
      id: json['id'] as String,
      invoiceNo: (json['invoice_no'] ?? '').toString(),
      invoiceType: (json['invoice_type'] ?? '').toString(),
      ncf: (json['ncf'] ?? '').toString().trim().isEmpty ? null : (json['ncf'] ?? '').toString(),
      customerId: (json['customer_id'] ?? '').toString().trim().isEmpty ? null : (json['customer_id'] ?? '').toString(),
      customerName: (json['customer_name'] ?? '').toString().trim().isEmpty ? null : (json['customer_name'] ?? '').toString(),
      customerRnc: (json['customer_rnc'] ?? '').toString().trim().isEmpty ? null : (json['customer_rnc'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      paymentMethod: (json['payment_method'] ?? '').toString().trim().isEmpty
          ? null
          : (json['payment_method'] ?? '').toString(),
      subtotal: _asDouble(json['subtotal']),
      discountTotal: _asDouble(json['discount_total']),
      itbisTotal: _asDouble(json['itbis_total']),
      total: _asDouble(json['total']),
      paidAmount: _asDouble(json['paid_amount']),
      changeAmount: _asDouble(json['change_amount']),
      note: (json['note'] ?? '').toString().trim().isEmpty ? null : (json['note'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()) ?? DateTime.now(),
      updatedAt: DateTime.tryParse((json['updated_at'] ?? '').toString()) ?? DateTime.now(),
      items: itemsJson
          .map((e) => PosSaleItem.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }
}

class PosPurchaseOrderItem {
  final String id;
  final String productId;
  final String productName;
  final double qty;
  final double unitCost;
  final double lineTotal;

  PosPurchaseOrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.qty,
    required this.unitCost,
    required this.lineTotal,
  });

  factory PosPurchaseOrderItem.fromJson(Map<String, dynamic> json) {
    return PosPurchaseOrderItem(
      id: json['id'] as String,
      productId: (json['product_id'] ?? '').toString(),
      productName: (json['product_name'] ?? '').toString(),
      qty: _asDouble(json['qty']),
      unitCost: _asDouble(json['unit_cost']),
      lineTotal: _asDouble(json['line_total']),
    );
  }
}

class PosPurchaseOrder {
  final String id;
  final String? supplierId;
  final String supplierName;
  final String status;
  final double subtotal;
  final double total;
  final DateTime createdAt;
  final List<PosPurchaseOrderItem> items;

  PosPurchaseOrder({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.status,
    required this.subtotal,
    required this.total,
    required this.createdAt,
    required this.items,
  });

  factory PosPurchaseOrder.fromJson(Map<String, dynamic> json) {
    final itemsJson = (json['items'] as List?)?.cast<Map>() ?? const [];

    final supplierIdRaw = (json['supplier_id'] ?? '').toString().trim();
    return PosPurchaseOrder(
      id: json['id'] as String,
      supplierId: supplierIdRaw.isEmpty ? null : supplierIdRaw,
      supplierName: (json['supplier_name'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      subtotal: _asDouble(json['subtotal']),
      total: _asDouble(json['total']),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()) ?? DateTime.now(),
      items: itemsJson
          .map((e) => PosPurchaseOrderItem.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }
}

class PosStockMovement {
  final String id;
  final String productId;
  final String productName;
  final String refType;
  final String? refId;
  final double qtyChange;
  final double unitCost;
  final String? note;
  final DateTime createdAt;

  PosStockMovement({
    required this.id,
    required this.productId,
    required this.productName,
    required this.refType,
    required this.refId,
    required this.qtyChange,
    required this.unitCost,
    required this.note,
    required this.createdAt,
  });

  factory PosStockMovement.fromJson(Map<String, dynamic> json) {
    return PosStockMovement(
      id: json['id'] as String,
      productId: (json['product_id'] ?? '').toString(),
      productName: (json['product_name'] ?? '').toString(),
      refType: (json['ref_type'] ?? '').toString(),
      refId: (json['ref_id'] ?? '').toString().trim().isEmpty ? null : (json['ref_id'] ?? '').toString(),
      qtyChange: _asDouble(json['qty_change']),
      unitCost: _asDouble(json['unit_cost']),
      note: (json['note'] ?? '').toString().trim().isEmpty ? null : (json['note'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()) ?? DateTime.now(),
    );
  }
}

class PosCreditAccountRow {
  final String id;
  final String saleId;
  final String invoiceNo;
  final String customerName;
  final double total;
  final double paid;
  final double balance;
  final DateTime? dueDate;
  final String status;
  final DateTime createdAt;

  PosCreditAccountRow({
    required this.id,
    required this.saleId,
    required this.invoiceNo,
    required this.customerName,
    required this.total,
    required this.paid,
    required this.balance,
    required this.dueDate,
    required this.status,
    required this.createdAt,
  });

  factory PosCreditAccountRow.fromJson(Map<String, dynamic> json) {
    return PosCreditAccountRow(
      id: json['id'] as String,
      saleId: (json['sale_id'] ?? '').toString(),
      invoiceNo: (json['invoice_no'] ?? '').toString(),
      customerName: (json['customer_name'] ?? '').toString(),
      total: _asDouble(json['total']),
      paid: _asDouble(json['paid']),
      balance: _asDouble(json['balance']),
      dueDate: (json['due_date'] == null)
          ? null
          : DateTime.tryParse(json['due_date'].toString()),
      status: (json['status'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()) ?? DateTime.now(),
    );
  }
}
