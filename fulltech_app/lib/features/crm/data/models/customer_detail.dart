class CustomerDetail {
  final String id;
  final String displayName;
  final String phone;
  final String waId;
  final String? avatarUrl;
  final String status;
  final PurchaseSummary summary;
  final List<RecentPurchase> recentPurchases;
  final List<TopProductDetail> topProducts;
  final List<CustomerNote> notes;

  const CustomerDetail({
    required this.id,
    required this.displayName,
    required this.phone,
    required this.waId,
    this.avatarUrl,
    required this.status,
    required this.summary,
    required this.recentPurchases,
    required this.topProducts,
    required this.notes,
  });

  factory CustomerDetail.fromJson(Map<String, dynamic> json) {
    return CustomerDetail(
      id: json['id'] as String,
      displayName: json['displayName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      waId: json['waId'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      status: json['status'] as String? ?? 'activo',
      summary: PurchaseSummary.fromJson(
        json['summary'] as Map<String, dynamic>? ?? {},
      ),
      recentPurchases: (json['recentPurchases'] as List<dynamic>? ?? [])
          .map((e) => RecentPurchase.fromJson(e as Map<String, dynamic>))
          .toList(),
      topProducts: (json['topProducts'] as List<dynamic>? ?? [])
          .map((e) => TopProductDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
      notes: (json['notes'] as List<dynamic>? ?? [])
          .map((e) => CustomerNote.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PurchaseSummary {
  final int totalPurchases;
  final double totalSpent;
  final String? lastPurchaseAt;

  const PurchaseSummary({
    required this.totalPurchases,
    required this.totalSpent,
    this.lastPurchaseAt,
  });

  factory PurchaseSummary.fromJson(Map<String, dynamic> json) {
    return PurchaseSummary(
      totalPurchases: (json['totalPurchases'] as num?)?.toInt() ?? 0,
      totalSpent: (json['totalSpent'] as num?)?.toDouble() ?? 0.0,
      lastPurchaseAt: json['lastPurchaseAt'] as String?,
    );
  }
}

class RecentPurchase {
  final String id;
  final String date;
  final double total;
  final String status;
  final List<PurchaseItem> items;

  const RecentPurchase({
    required this.id,
    required this.date,
    required this.total,
    required this.status,
    required this.items,
  });

  factory RecentPurchase.fromJson(Map<String, dynamic> json) {
    return RecentPurchase(
      id: json['id'] as String,
      date: json['date'] as String,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'completed',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => PurchaseItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PurchaseItem {
  final String? productId;
  final String name;
  final int qty;
  final double price;
  final String imageUrl;

  const PurchaseItem({
    this.productId,
    required this.name,
    required this.qty,
    required this.price,
    required this.imageUrl,
  });

  factory PurchaseItem.fromJson(Map<String, dynamic> json) {
    return PurchaseItem(
      productId: json['productId'] as String?,
      name: json['name'] as String? ?? 'Producto',
      qty: (json['qty'] as num?)?.toInt() ?? 1,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['imageUrl'] as String? ?? '',
    );
  }
}

class TopProductDetail {
  final String productId;
  final String name;
  final int count;
  final String imageUrl;

  const TopProductDetail({
    required this.productId,
    required this.name,
    required this.count,
    required this.imageUrl,
  });

  factory TopProductDetail.fromJson(Map<String, dynamic> json) {
    return TopProductDetail(
      productId: json['productId'] as String,
      name: json['name'] as String? ?? 'Producto',
      count: (json['count'] as num?)?.toInt() ?? 0,
      imageUrl: json['imageUrl'] as String? ?? '',
    );
  }
}

class CustomerNote {
  final String id;
  final String text;
  final String? followUpAt;
  final String priority;
  final String createdAt;
  final String? createdBy;

  const CustomerNote({
    required this.id,
    required this.text,
    this.followUpAt,
    required this.priority,
    required this.createdAt,
    this.createdBy,
  });

  factory CustomerNote.fromJson(Map<String, dynamic> json) {
    return CustomerNote(
      id: json['id'] as String,
      text: json['text'] as String? ?? '',
      followUpAt: json['followUpAt'] as String?,
      priority: json['priority'] as String? ?? 'normal',
      createdAt: json['createdAt'] as String,
      createdBy: json['createdBy'] as String?,
    );
  }
}
