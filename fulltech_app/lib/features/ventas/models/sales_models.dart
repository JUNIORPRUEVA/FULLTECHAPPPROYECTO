import 'dart:convert';

class SalesPaymentMethod {
  static const cash = 'cash';
  static const card = 'card';
  static const transfer = 'transfer';
  static const other = 'other';

  static const all = <String>[cash, card, transfer, other];
}

class SalesChannel {
  static const whatsapp = 'whatsapp';
  static const instagram = 'instagram';
  static const facebook = 'facebook';
  static const call = 'call';
  static const walkin = 'walkin';
  static const other = 'other';

  static const all = <String>[whatsapp, instagram, facebook, call, walkin, other];
}

class SalesStatus {
  static const confirmed = 'confirmed';
  static const pending = 'pending';
  static const cancelled = 'cancelled';

  static const all = <String>[confirmed, pending, cancelled];
}

class SalesEvidenceType {
  static const image = 'image';
  static const pdf = 'pdf';
  static const link = 'link';
  static const text = 'text';

  static const all = <String>[image, pdf, link, text];
}

class SyncStatus {
  static const pending = 'pending';
  static const synced = 'synced';
  static const error = 'error';
}

class SalesRecord {
  final String id;
  final String empresaId;
  final String userId;

  final String? customerName;
  final String? customerPhone;
  final String? customerDocument;

  final String productOrService;
  final List<SalesLineItem> items;
  final double amount;
  final String paymentMethod;
  final String channel;
  final String status;
  final String? notes;

  final DateTime soldAt;

  final bool evidenceRequired;
  final int evidenceCount;

  final bool deleted;
  final DateTime? deletedAt;

  final DateTime createdAt;
  final DateTime updatedAt;

  final String syncStatus;
  final String? lastError;

  const SalesRecord({
    required this.id,
    required this.empresaId,
    required this.userId,
    required this.customerName,
    required this.customerPhone,
    required this.customerDocument,
    required this.productOrService,
    required this.items,
    required this.amount,
    required this.paymentMethod,
    required this.channel,
    required this.status,
    required this.notes,
    required this.soldAt,
    required this.evidenceRequired,
    required this.evidenceCount,
    required this.deleted,
    required this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    required this.lastError,
  });

  static DateTime _parseDate(dynamic v) {
    if (v is DateTime) return v;
    if (v is String) {
      final dt = DateTime.tryParse(v);
      if (dt != null) return dt;
    }
    return DateTime.now();
  }

  static double _parseAmount(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  factory SalesRecord.fromServerJson(Map<String, dynamic> json, {
    required String empresaId,
    String syncStatus = SyncStatus.synced,
  }) {
    final details = json['details'];
    final items = <SalesLineItem>[];
    if (details is Map<String, dynamic>) {
      final rawItems = details['items'];
      if (rawItems is List) {
        for (final it in rawItems) {
          if (it is Map<String, dynamic>) {
            items.add(SalesLineItem.fromJson(it));
          } else if (it is Map) {
            items.add(SalesLineItem.fromJson(it.cast<String, dynamic>()));
          }
        }
      }
    }

    return SalesRecord(
      id: (json['id'] ?? '').toString(),
      empresaId: empresaId,
      userId: (json['user_id'] ?? json['userId'] ?? '').toString(),
      customerName: (json['customer_name'] as String?)?.trim().isEmpty == true ? null : json['customer_name'] as String?,
      customerPhone: (json['customer_phone'] as String?)?.trim().isEmpty == true ? null : json['customer_phone'] as String?,
      customerDocument: (json['customer_document'] as String?)?.trim().isEmpty == true ? null : json['customer_document'] as String?,
      productOrService: (json['product_or_service'] ?? '').toString(),
      items: items,
      amount: _parseAmount(json['amount']),
      paymentMethod: (json['payment_method'] ?? SalesPaymentMethod.other).toString(),
      channel: (json['channel'] ?? SalesChannel.other).toString(),
      status: (json['status'] ?? SalesStatus.confirmed).toString(),
      notes: (json['notes'] as String?)?.trim().isEmpty == true ? null : json['notes'] as String?,
      soldAt: _parseDate(json['sold_at']),
      evidenceRequired: json['evidence_required'] == true || json['evidence_required'] == 1,
      evidenceCount: (json['evidence_count'] as num?)?.toInt() ?? 0,
      deleted: json['deleted'] == true || json['deleted'] == 1,
      deletedAt: json['deleted_at'] == null ? null : DateTime.tryParse(json['deleted_at'].toString()),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      syncStatus: syncStatus,
      lastError: null,
    );
  }

  factory SalesRecord.fromLocalRow(Map<String, Object?> row) {
    final items = <SalesLineItem>[];
    final detailsJson = row['details_json'] as String?;
    if (detailsJson != null && detailsJson.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(detailsJson);
        if (decoded is Map<String, dynamic>) {
          final rawItems = decoded['items'];
          if (rawItems is List) {
            for (final it in rawItems) {
              if (it is Map<String, dynamic>) {
                items.add(SalesLineItem.fromJson(it));
              } else if (it is Map) {
                items.add(SalesLineItem.fromJson(it.cast<String, dynamic>()));
              }
            }
          }
        }
      } catch (_) {
        // ignore
      }
    }

    return SalesRecord(
      id: row['id'] as String,
      empresaId: row['empresa_id'] as String,
      userId: row['user_id'] as String,
      customerName: row['customer_name'] as String?,
      customerPhone: row['customer_phone'] as String?,
      customerDocument: row['customer_document'] as String?,
      productOrService: (row['product_or_service'] ?? '') as String,
      items: items,
      amount: (row['amount'] as num).toDouble(),
      paymentMethod: (row['payment_method'] ?? SalesPaymentMethod.other) as String,
      channel: (row['channel'] ?? SalesChannel.other) as String,
      status: (row['status'] ?? SalesStatus.confirmed) as String,
      notes: row['notes'] as String?,
      soldAt: DateTime.tryParse(row['sold_at'] as String) ?? DateTime.now(),
      evidenceRequired: (row['evidence_required'] as int) == 1,
      evidenceCount: (row['evidence_count'] as int?) ?? 0,
      deleted: (row['deleted'] as int) == 1,
      deletedAt: row['deleted_at'] == null ? null : DateTime.tryParse(row['deleted_at'] as String),
      createdAt: DateTime.tryParse(row['created_at'] as String) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(row['updated_at'] as String) ?? DateTime.now(),
      syncStatus: (row['sync_status'] ?? SyncStatus.pending) as String,
      lastError: row['last_error'] as String?,
    );
  }

  Map<String, Object?> toLocalRow({int? overrideEvidenceCount}) {
    final details = items.isEmpty
        ? null
        : jsonEncode({
            'items': items.map((e) => e.toJson()).toList(growable: false),
          });

    return {
      'id': id,
      'empresa_id': empresaId,
      'user_id': userId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_document': customerDocument,
      'product_or_service': productOrService,
      'details_json': details,
      'amount': amount,
      'payment_method': paymentMethod,
      'channel': channel,
      'status': status,
      'notes': notes,
      'sold_at': soldAt.toIso8601String(),
      'evidence_required': evidenceRequired ? 1 : 0,
      'deleted': deleted ? 1 : 0,
      'deleted_at': deletedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'sync_status': syncStatus,
      'last_error': lastError,
      'evidence_count': overrideEvidenceCount ?? evidenceCount,
    };
  }

  Map<String, dynamic> toCreatePayload() {
    return {
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_document': customerDocument,
      'product_or_service': productOrService,
      if (items.isNotEmpty)
        'details': {
          'items': items.map((e) => e.toJson()).toList(growable: false),
        },
      'amount': amount,
      'payment_method': paymentMethod,
      'channel': channel,
      'status': status,
      'notes': notes,
      'sold_at': soldAt.toIso8601String(),
      'evidence_required': evidenceRequired,
    };
  }

  SalesRecord copyWith({
    String? syncStatus,
    String? lastError,
    int? evidenceCount,
    List<SalesLineItem>? items,
  }) {
    return SalesRecord(
      id: id,
      empresaId: empresaId,
      userId: userId,
      customerName: customerName,
      customerPhone: customerPhone,
      customerDocument: customerDocument,
      productOrService: productOrService,
      items: items ?? this.items,
      amount: amount,
      paymentMethod: paymentMethod,
      channel: channel,
      status: status,
      notes: notes,
      soldAt: soldAt,
      evidenceRequired: evidenceRequired,
      evidenceCount: evidenceCount ?? this.evidenceCount,
      deleted: deleted,
      deletedAt: deletedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastError: lastError ?? this.lastError,
    );
  }
}

class SalesLineItem {
  final String id;
  final String name;
  final int quantity;
  final double unitPrice;
  final String? productId;

  const SalesLineItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.productId,
  });

  double get total => unitPrice * quantity;

  factory SalesLineItem.fromJson(Map<String, dynamic> json) {
    final q = json['quantity'];
    final p = json['unit_price'];
    return SalesLineItem(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      quantity: q is num ? q.toInt() : int.tryParse(q?.toString() ?? '') ?? 1,
      unitPrice: p is num ? p.toDouble() : double.tryParse(p?.toString() ?? '') ?? 0,
      productId: (json['product_id'] ?? json['productId'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'unit_price': unitPrice,
      if (productId != null && productId!.trim().isNotEmpty) 'product_id': productId,
    };
  }
}

class SalesEvidence {
  final String id;
  final String saleId;
  final String type;
  final String urlOrPath;
  final String? caption;
  final DateTime createdAt;
  final String syncStatus;
  final String? lastError;

  const SalesEvidence({
    required this.id,
    required this.saleId,
    required this.type,
    required this.urlOrPath,
    required this.caption,
    required this.createdAt,
    required this.syncStatus,
    required this.lastError,
  });

  factory SalesEvidence.fromServerJson(Map<String, dynamic> json, {
    required String saleId,
    String syncStatus = SyncStatus.synced,
  }) {
    return SalesEvidence(
      id: (json['id'] ?? '').toString(),
      saleId: saleId,
      type: (json['type'] ?? SalesEvidenceType.image).toString(),
      urlOrPath: (json['url_or_path'] ?? json['urlOrPath'] ?? '').toString(),
      caption: (json['caption'] as String?)?.trim().isEmpty == true ? null : json['caption'] as String?,
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()) ?? DateTime.now(),
      syncStatus: syncStatus,
      lastError: null,
    );
  }

  factory SalesEvidence.fromLocalRow(Map<String, Object?> row) {
    return SalesEvidence(
      id: row['id'] as String,
      saleId: row['sale_id'] as String,
      type: row['type'] as String,
      urlOrPath: row['url_or_path'] as String,
      caption: row['caption'] as String?,
      createdAt: DateTime.tryParse(row['created_at'] as String) ?? DateTime.now(),
      syncStatus: (row['sync_status'] ?? SyncStatus.pending) as String,
      lastError: row['last_error'] as String?,
    );
  }

  Map<String, Object?> toLocalRow() {
    return {
      'id': id,
      'sale_id': saleId,
      'type': type,
      'url_or_path': urlOrPath,
      'caption': caption,
      'created_at': createdAt.toIso8601String(),
      'sync_status': syncStatus,
      'last_error': lastError,
    };
  }

  Map<String, dynamic> toCreatePayload() {
    return {
      'type': type,
      // Backend expects file_path/url/text; it maps to url_or_path.
      if (type == SalesEvidenceType.link) 'url': urlOrPath,
      if (type == SalesEvidenceType.text) 'text': urlOrPath,
      if (type == SalesEvidenceType.image || type == SalesEvidenceType.pdf) 'file_path': urlOrPath,
      if (caption != null) 'mime_type': caption,
    };
  }

  SalesEvidence copyWith({
    String? urlOrPath,
    String? syncStatus,
    String? lastError,
    String? caption,
  }) {
    return SalesEvidence(
      id: id,
      saleId: saleId,
      type: type,
      urlOrPath: urlOrPath ?? this.urlOrPath,
      caption: caption ?? this.caption,
      createdAt: createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastError: lastError ?? this.lastError,
    );
  }
}
