class Customer {
  final String id;
  final String empresaId;
  final String nombre;
  final String telefono;
  final String? email;
  final String? direccion;
  final String? ubicacionMapa;
  final List<String> tags;
  final String? notas;
  final String origen;
  final int syncVersion;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Customer({
    required this.id,
    required this.empresaId,
    required this.nombre,
    required this.telefono,
    required this.email,
    required this.direccion,
    required this.ubicacionMapa,
    required this.tags,
    required this.notas,
    required this.origen,
    required this.syncVersion,
    required this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  static DateTime? _dtOrNull(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  static DateTime _dt(dynamic v) {
    final parsed = _dtOrNull(v);
    if (parsed == null) throw Exception('Invalid datetime: $v');
    return parsed;
  }

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: (json['id'] ?? '') as String,
      empresaId: (json['empresa_id'] ?? '') as String,
      nombre: (json['nombre'] ?? '') as String,
      telefono: (json['telefono'] ?? '') as String,
      email: json['email'] as String?,
      direccion: json['direccion'] as String?,
      ubicacionMapa: json['ubicacion_mapa'] as String?,
      tags: (json['tags'] as List<dynamic>? ?? const <dynamic>[]).cast<String>(),
      notas: json['notas'] as String?,
      origen: (json['origen'] ?? 'whatsapp') as String,
      syncVersion: (json['sync_version'] as num? ?? 1).toInt(),
      deletedAt: _dtOrNull(json['deleted_at']),
      createdAt: _dt(json['created_at']),
      updatedAt: _dt(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'empresa_id': empresaId,
      'nombre': nombre,
      'telefono': telefono,
      'email': email,
      'direccion': direccion,
      'ubicacion_mapa': ubicacionMapa,
      'tags': tags,
      'notas': notas,
      'origen': origen,
      'sync_version': syncVersion,
      'deleted_at': deletedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
