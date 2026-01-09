import 'pos_models.dart';

enum PosDiscountType {
  fixed,
  percent,
  ;

  static PosDiscountType fromJson(dynamic v) {
    final s = (v ?? '').toString().trim().toLowerCase();
    return s == 'percent' ? PosDiscountType.percent : PosDiscountType.fixed;
  }

  String toJson() => this == PosDiscountType.percent ? 'percent' : 'fixed';
}

class PosTicket {
  final String id;
  final String name;
  final bool isCustomName;

  final String? customerId;
  final String? customerName;
  final String? customerPhone;
  final String? customerRnc;

  final PosDiscountType discountType;
  final double discountValue;

  final bool itbisEnabled;
  final double itbisRate;

  final bool ncfEnabled;
  final String? selectedNcfDocType;

  final List<PosSaleItemDraft> items;

  const PosTicket({
    required this.id,
    required this.name,
    required this.isCustomName,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.customerRnc,
    required this.discountType,
    required this.discountValue,
    required this.itbisEnabled,
    required this.itbisRate,
    required this.ncfEnabled,
    required this.selectedNcfDocType,
    required this.items,
  });

  double get subtotal =>
      items.fold<double>(0, (acc, it) => acc + (it.qty * it.unitPrice));

  double get lineDiscounts =>
      items.fold<double>(0, (acc, it) => acc + it.discountAmount);

  /// Computed global discount amount (not the raw [discountValue]).
  ///
  /// For percent discounts, it's applied over the base after line discounts.
  double get globalDiscount {
    double clamp0(double v) => v < 0 ? 0 : v;

    final baseAfterLine = clamp0(subtotal - lineDiscounts);
    if (baseAfterLine <= 0) return 0.0;

    final v = discountValue.isNaN || discountValue.isInfinite ? 0.0 : discountValue;
    if (discountType == PosDiscountType.percent) {
      final p = v.clamp(0, 100).toDouble();
      final amt = baseAfterLine * (p / 100.0);
      return amt > baseAfterLine ? baseAfterLine : amt;
    }

    final amt = v < 0 ? 0.0 : v;
    return amt > baseAfterLine ? baseAfterLine : amt;
  }

  String get invoiceType => ncfEnabled ? 'FISCAL' : 'NORMAL';

  PosTicket copyWith({
    String? name,
    bool? isCustomName,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? customerRnc,
    PosDiscountType? discountType,
    double? discountValue,
    bool? itbisEnabled,
    double? itbisRate,
    bool? ncfEnabled,
    String? selectedNcfDocType,
    List<PosSaleItemDraft>? items,
  }) {
    return PosTicket(
      id: id,
      name: name ?? this.name,
      isCustomName: isCustomName ?? this.isCustomName,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerRnc: customerRnc ?? this.customerRnc,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      itbisEnabled: itbisEnabled ?? this.itbisEnabled,
      itbisRate: itbisRate ?? this.itbisRate,
      ncfEnabled: ncfEnabled ?? this.ncfEnabled,
      selectedNcfDocType: selectedNcfDocType ?? this.selectedNcfDocType,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'is_custom_name': isCustomName,
        'customer_id': customerId,
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'customer_rnc': customerRnc,
        'discount_type': discountType.toJson(),
        'discount_value': discountValue,
        'itbis_enabled': itbisEnabled,
        'itbis_rate': itbisRate,
        'ncf_enabled': ncfEnabled,
        'selected_ncf_doc_type': selectedNcfDocType,
        'items': items
            .map(
              (it) => {
                'product': it.product.toJson(),
                'qty': it.qty,
                'unit_price': it.unitPrice,
                'discount_amount': it.discountAmount,
              },
            )
            .toList(),
      };

  static PosTicket fromJson(Map<String, dynamic> json) {
    final itemsJson = (json['items'] as List?)?.cast<Map>() ?? const [];

    final items = itemsJson.map((m) {
      final mm = m.cast<String, dynamic>();
      final product = PosProduct.fromJson((mm['product'] as Map).cast<String, dynamic>());
      return PosSaleItemDraft(
        product: product,
        qty: (mm['qty'] as num?)?.toDouble() ?? 0,
        unitPrice: (mm['unit_price'] as num?)?.toDouble() ?? 0,
        discountAmount: (mm['discount_amount'] as num?)?.toDouble() ?? 0,
      );
    }).toList();

    bool asBool(dynamic v) => v == true || (v?.toString().toLowerCase() == 'true');
    double asDouble(dynamic v, double fallback) {
      if (v == null) return fallback;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? fallback;
    }

    String? cleanNullable(dynamic v) {
      final s = (v ?? '').toString().trim();
      return s.isEmpty ? null : s;
    }

    return PosTicket(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      isCustomName: asBool(json['is_custom_name']),
      customerId: cleanNullable(json['customer_id']),
      customerName: cleanNullable(json['customer_name']),
      customerPhone: cleanNullable(json['customer_phone']),
      customerRnc: cleanNullable(json['customer_rnc']),
      discountType: PosDiscountType.fromJson(json['discount_type']),
      discountValue: asDouble(json['discount_value'], 0),
      itbisEnabled: asBool(json['itbis_enabled']),
      itbisRate: asDouble(json['itbis_rate'], 0.18),
      ncfEnabled: asBool(json['ncf_enabled']),
      selectedNcfDocType: cleanNullable(json['selected_ncf_doc_type']),
      items: items,
    );
  }
}
