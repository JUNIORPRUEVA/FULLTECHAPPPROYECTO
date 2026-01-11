/// CRM Instance model - Per-user Evolution API configuration
class CrmInstance {
  final String id;
  final String empresaId;
  final String userId;
  final String nombreInstancia;
  final String evolutionBaseUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CrmInstance({
    required this.id,
    required this.empresaId,
    required this.userId,
    required this.nombreInstancia,
    required this.evolutionBaseUrl,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CrmInstance.fromJson(Map<String, dynamic> json) {
    return CrmInstance(
      id: json['id'] as String,
      empresaId: json['empresa_id'] as String,
      userId: json['user_id'] as String,
      nombreInstancia: json['nombre_instancia'] as String,
      evolutionBaseUrl: json['evolution_base_url'] as String,
      isActive: json['is_active'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'empresa_id': empresaId,
    'user_id': userId,
    'nombre_instancia': nombreInstancia,
    'evolution_base_url': evolutionBaseUrl,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}

// ======================================
// Transfer User Model
// ======================================

class CrmTransferUser {
  final String id;
  final String username;
  final String? email;
  final String instanceId;
  final String nombreInstancia;

  const CrmTransferUser({
    required this.id,
    required this.username,
    this.email,
    required this.instanceId,
    required this.nombreInstancia,
  });

  factory CrmTransferUser.fromJson(Map<String, dynamic> json) {
    return CrmTransferUser(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String?,
      instanceId: json['instance_id'] as String,
      nombreInstancia: json['nombre_instancia'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'email': email,
    'instance_id': instanceId,
    'nombre_instancia': nombreInstancia,
  };
}
