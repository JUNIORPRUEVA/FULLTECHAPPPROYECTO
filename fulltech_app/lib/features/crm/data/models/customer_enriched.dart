class CustomerEnriched {
  final String id;
  final String displayName;
  final String phone;
  final String waId;
  final String? avatarUrl;
  final String status;
  final String? lastPurchaseAt;
  final int totalPurchases;
  final double totalSpent;
  final TopProduct? topProduct;

  const CustomerEnriched({
    required this.id,
    required this.displayName,
    required this.phone,
    required this.waId,
    this.avatarUrl,
    required this.status,
    this.lastPurchaseAt,
    required this.totalPurchases,
    required this.totalSpent,
    this.topProduct,
  });

  factory CustomerEnriched.fromJson(Map<String, dynamic> json) {
    return CustomerEnriched(
      id: json['id'] as String,
      displayName: json['displayName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      waId: json['waId'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      status: json['status'] as String? ?? 'activo',
      lastPurchaseAt: json['lastPurchaseAt'] as String?,
      totalPurchases: (json['totalPurchases'] as num?)?.toInt() ?? 0,
      totalSpent: (json['totalSpent'] as num?)?.toDouble() ?? 0.0,
      topProduct: json['topProduct'] != null
          ? TopProduct.fromJson(json['topProduct'] as Map<String, dynamic>)
          : null,
    );
  }
}

class TopProduct {
  final String? id;
  final String name;
  final String imageUrl;
  final double price;

  const TopProduct({
    this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
  });

  factory TopProduct.fromJson(Map<String, dynamic> json) {
    return TopProduct(
      id: json['id'] as String?,
      name: json['name'] as String? ?? 'Producto',
      imageUrl: json['imageUrl'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
