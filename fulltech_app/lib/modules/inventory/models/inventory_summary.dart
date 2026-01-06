class InventorySummary {
  final int totalProducts;
  final int lowStock;
  final int outOfStock;
  final double valuation;

  const InventorySummary({
    required this.totalProducts,
    required this.lowStock,
    required this.outOfStock,
    required this.valuation,
  });

  factory InventorySummary.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0;
      return 0;
    }

    int toInt(dynamic v) {
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return InventorySummary(
      totalProducts: toInt(json['total_products']),
      lowStock: toInt(json['low_stock']),
      outOfStock: toInt(json['out_of_stock']),
      valuation: toDouble(json['valuation']),
    );
  }
}
