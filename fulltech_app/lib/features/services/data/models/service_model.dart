class ServiceModel {
  final String id;
  final String empresaId;
  final String name;
  final String? description;
  final double? defaultPrice;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String syncStatus;
  final String? lastError;

  ServiceModel({
    required this.id,
    required this.empresaId,
    required this.name,
    this.description,
    this.defaultPrice,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    this.lastError,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] as String,
      empresaId: json['empresa_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      defaultPrice: json['default_price'] != null
          ? (json['default_price'] as num).toDouble()
          : null,
      isActive: json['is_active'] == true || json['is_active'] == 1,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      syncStatus: json['sync_status'] as String? ?? 'synced',
      lastError: json['last_error'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'empresa_id': empresaId,
      'name': name,
      'description': description,
      'default_price': defaultPrice,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'sync_status': syncStatus,
      'last_error': lastError,
    };
  }

  Map<String, dynamic> toLocalDb() {
    return {
      'id': id,
      'empresa_id': empresaId,
      'name': name,
      'description': description,
      'default_price': defaultPrice,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'sync_status': syncStatus,
      'last_error': lastError,
    };
  }

  ServiceModel copyWith({
    String? id,
    String? empresaId,
    String? name,
    String? description,
    double? defaultPrice,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? syncStatus,
    String? lastError,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      empresaId: empresaId ?? this.empresaId,
      name: name ?? this.name,
      description: description ?? this.description,
      defaultPrice: defaultPrice ?? this.defaultPrice,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastError: lastError ?? this.lastError,
    );
  }
}
