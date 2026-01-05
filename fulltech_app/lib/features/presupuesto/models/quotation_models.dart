class QuotationSummary {
  final String id;
  final String numero;
  final String customerName;
  final double total;
  final DateTime createdAt;

  const QuotationSummary({
    required this.id,
    required this.numero,
    required this.customerName,
    required this.total,
    required this.createdAt,
  });

  factory QuotationSummary.fromJson(Map<String, dynamic> json) {
    return QuotationSummary(
      id: json['id'] as String,
      numero: (json['numero'] ?? '') as String,
      customerName: (json['customer_name'] ?? '') as String,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

enum QuotationDiscountMode { percent, amount }

QuotationDiscountMode _discountModeFromJson(dynamic v) {
  final s = (v ?? '').toString().trim().toLowerCase();
  if (s == 'amount' || s == 'monto' || s == 'rd' || s == 'money') {
    return QuotationDiscountMode.amount;
  }
  return QuotationDiscountMode.percent;
}

class QuotationItemDraft {
  final String localId;
  final String? productId;
  final String nombre;
  final double cantidad;
  final double unitPrice;
  final double? unitCost;
  final double discountPct;
  final double discountAmount;
  final QuotationDiscountMode discountMode;

  const QuotationItemDraft({
    required this.localId,
    required this.productId,
    required this.nombre,
    required this.cantidad,
    required this.unitPrice,
    required this.unitCost,
    required this.discountPct,
    required this.discountAmount,
    required this.discountMode,
  });

  QuotationItemDraft copyWith({
    String? localId,
    String? productId,
    String? nombre,
    double? cantidad,
    double? unitPrice,
    double? unitCost,
    double? discountPct,
    double? discountAmount,
    QuotationDiscountMode? discountMode,
  }) {
    return QuotationItemDraft(
      localId: localId ?? this.localId,
      productId: productId ?? this.productId,
      nombre: nombre ?? this.nombre,
      cantidad: cantidad ?? this.cantidad,
      unitPrice: unitPrice ?? this.unitPrice,
      unitCost: unitCost ?? this.unitCost,
      discountPct: discountPct ?? this.discountPct,
      discountAmount: discountAmount ?? this.discountAmount,
      discountMode: discountMode ?? this.discountMode,
    );
  }

  double get lineGross => cantidad * unitPrice;

  double get lineDiscount {
    final gross = lineGross;
    if (gross <= 0) return 0;
    if (discountMode == QuotationDiscountMode.amount) {
      return discountAmount.clamp(0, gross);
    }
    return (gross * (discountPct / 100)).clamp(0, gross);
  }

  double get lineNet => (lineGross - lineDiscount).clamp(0, double.infinity);

  Map<String, dynamic> toCreateJson() {
    return {
      if (productId != null) 'product_id': productId,
      'nombre': nombre,
      'cantidad': cantidad,
      'unit_price': unitPrice,
      if (unitCost != null) 'unit_cost': unitCost,
      if (discountMode == QuotationDiscountMode.amount && discountAmount > 0)
        'discount_amount': discountAmount,
      if (discountMode == QuotationDiscountMode.percent && discountPct > 0)
        'discount_pct': discountPct,
    };
  }

  static QuotationItemDraft fromDraftJson(Map<String, dynamic> raw) {
    final localId = (raw['local_id'] ?? '').toString();
    return QuotationItemDraft(
      localId: localId,
      productId: raw['product_id']?.toString(),
      nombre: (raw['nombre'] ?? '').toString(),
      cantidad: (raw['cantidad'] as num?)?.toDouble() ?? 1,
      unitPrice: (raw['unit_price'] as num?)?.toDouble() ?? 0,
      unitCost: (raw['unit_cost'] as num?)?.toDouble(),
      discountPct: (raw['discount_pct'] as num?)?.toDouble() ?? 0,
      discountAmount: (raw['discount_amount'] as num?)?.toDouble() ?? 0,
      discountMode: _discountModeFromJson(raw['discount_mode']),
    );
  }

  Map<String, dynamic> toDraftJson() {
    return {
      'local_id': localId,
      'product_id': productId,
      'nombre': nombre,
      'cantidad': cantidad,
      'unit_price': unitPrice,
      'unit_cost': unitCost,
      'discount_pct': discountPct,
      'discount_amount': discountAmount,
      'discount_mode': discountMode.name,
    };
  }
}

class QuotationCustomerDraft {
  final String? id;
  final String nombre;
  final String? telefono;
  final String? email;

  const QuotationCustomerDraft({
    required this.id,
    required this.nombre,
    required this.telefono,
    required this.email,
  });
}
