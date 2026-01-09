import '../models/pos_ticket.dart';

class PosPricingSummary {
  final double grossSubtotal;
  final double lineDiscounts;
  final double globalDiscount;
  final double base;
  final double itbis;
  final double total;

  const PosPricingSummary({
    required this.grossSubtotal,
    required this.lineDiscounts,
    required this.globalDiscount,
    required this.base,
    required this.itbis,
    required this.total,
  });
}

double _clamp0(double v) => v < 0 ? 0 : v;

double computeGlobalDiscountAmount({
  required double baseAfterLineDiscounts,
  required PosDiscountType type,
  required double value,
}) {
  final safeBase = _clamp0(baseAfterLineDiscounts);
  final safeValue = value.isNaN || value.isInfinite ? 0 : value;

  if (safeBase <= 0) return 0;

  if (type == PosDiscountType.percent) {
    final p = safeValue.clamp(0, 100);
    final amt = safeBase * (p / 100.0);
    return amt > safeBase ? safeBase : amt;
  }

  final amt = safeValue < 0 ? 0 : safeValue;
  return amt > safeBase ? safeBase : amt;
}

PosPricingSummary computeTicketPricing({
  required double grossSubtotal,
  required double lineDiscounts,
  required PosDiscountType discountType,
  required double discountValue,
  required bool itbisEnabled,
  required double itbisRate,
}) {
  final gs = _clamp0(grossSubtotal);
  final ld = _clamp0(lineDiscounts);
  final baseAfterLine = _clamp0(gs - ld);

  final globalDiscount = computeGlobalDiscountAmount(
    baseAfterLineDiscounts: baseAfterLine,
    type: discountType,
    value: discountValue,
  );

  final base = _clamp0(baseAfterLine - globalDiscount);
  final rate = itbisEnabled ? (itbisRate.isNaN || itbisRate.isInfinite ? 0 : itbisRate) : 0;
  final itbis = rate <= 0 ? 0 : base * rate;
  final total = base + itbis;

  return PosPricingSummary(
    grossSubtotal: gs,
    lineDiscounts: ld,
    globalDiscount: globalDiscount,
    base: base,
    itbis: itbis,
    total: total,
  );
}
