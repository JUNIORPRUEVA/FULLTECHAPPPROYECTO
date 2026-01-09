class PosDiscount {
  final String type; // AMOUNT|PERCENT
  final double value;

  const PosDiscount({required this.type, required this.value});

  static const none = PosDiscount(type: 'AMOUNT', value: 0);

  Map<String, dynamic> toJson() => {'type': type, 'value': value};

  factory PosDiscount.fromJson(Map<String, dynamic> json) {
    return PosDiscount(
      type: (json['type'] ?? 'AMOUNT').toString(),
      value: (json['value'] is num) ? (json['value'] as num).toDouble() : 0,
    );
  }
}

class PosTicketTotals {
  final double grossSubtotal;
  final double lineDiscounts;
  final double baseAfterLineDiscounts;
  final double globalDiscount;
  final double discountTotal;
  final double taxableBase;
  final double itbisRate;
  final bool itbisEnabled;
  final double itbisTotal;
  final double total;

  const PosTicketTotals({
    required this.grossSubtotal,
    required this.lineDiscounts,
    required this.baseAfterLineDiscounts,
    required this.globalDiscount,
    required this.discountTotal,
    required this.taxableBase,
    required this.itbisRate,
    required this.itbisEnabled,
    required this.itbisTotal,
    required this.total,
  });
}

class PosPricing {
  static double _clamp0(double v) => v < 0 ? 0 : v;

  static double computeGlobalDiscountAmount({
    required PosDiscount discount,
    required double baseAfterLineDiscounts,
  }) {
    final value = discount.value;
    if (value <= 0) return 0;

    if (discount.type == 'PERCENT') {
      final pct = value;
      final computed = baseAfterLineDiscounts * (pct / 100.0);
      return _clamp0(computed);
    }

    return _clamp0(value);
  }

  static String? validateGlobalDiscount({
    required PosDiscount discount,
    required double baseAfterLineDiscounts,
  }) {
    if (discount.value < 0) return 'El descuento no puede ser negativo';

    if (discount.type == 'PERCENT') {
      if (discount.value > 100) return 'El descuento % debe ser 0 a 100';
      return null;
    }

    if (discount.value > baseAfterLineDiscounts) {
      return 'El descuento no puede ser mayor al subtotal';
    }

    return null;
  }

  static String? validateItbisRatePercent(double percent) {
    if (percent < 0) return 'El ITBIS no puede ser negativo';
    if (percent > 100) return 'El ITBIS % debe ser 0 a 100';
    return null;
  }

  static PosTicketTotals totals({
    required double grossSubtotal,
    required double lineDiscounts,
    required double baseAfterLineDiscounts,
    required PosDiscount globalDiscount,
    required bool itbisEnabled,
    required double itbisRate,
  }) {
    final globalDiscountAmount = computeGlobalDiscountAmount(
      discount: globalDiscount,
      baseAfterLineDiscounts: baseAfterLineDiscounts,
    );

    final discountTotal = _clamp0(lineDiscounts + globalDiscountAmount);
    final taxableBase = _clamp0(baseAfterLineDiscounts - globalDiscountAmount);

    final rate = itbisEnabled ? (itbisRate < 0 ? 0 : itbisRate) : 0;
    final itbisTotal = _clamp0(taxableBase * rate);
    final total = _clamp0(taxableBase + itbisTotal);

    return PosTicketTotals(
      grossSubtotal: _clamp0(grossSubtotal),
      lineDiscounts: _clamp0(lineDiscounts),
      baseAfterLineDiscounts: _clamp0(baseAfterLineDiscounts),
      globalDiscount: globalDiscountAmount,
      discountTotal: discountTotal,
      taxableBase: taxableBase,
      itbisRate: itbisRate,
      itbisEnabled: itbisEnabled,
      itbisTotal: itbisTotal,
      total: total,
    );
  }
}
