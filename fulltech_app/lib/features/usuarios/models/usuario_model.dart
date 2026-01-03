class UsuarioModel {
  final String id;
  final String nombre_completo;
  final String email;
  final String rol;
  final String? posicion;
  final String? telefono;
  final String? direccion;
  final String? ubicacion_mapa;
  final DateTime? fecha_nacimiento;
  final int? edad;
  final String? lugar_nacimiento;
  final String? cedula_numero;
  final bool? tiene_casa_propia;
  final bool? tiene_vehiculo;
  final String? tipo_vehiculo;
  final bool? es_casado;
  final int? cantidad_hijos;
  final String? ultimo_trabajo;
  final String? motivo_salida_ultimo_trabajo;
  final DateTime? fecha_ingreso_empresa;
  final Decimal? salario_mensual;
  final String? beneficios;
  final bool? es_tecnico_con_licencia;
  final String? numero_licencia;
  final String? foto_perfil_url;
  final String? cedula_foto_url;
  final String? carta_ultimo_trabajo_url;
  final String estado;
  final DateTime created_at;
  final DateTime updated_at;

  UsuarioModel({
    required this.id,
    required this.nombre_completo,
    required this.email,
    required this.rol,
    this.posicion,
    this.telefono,
    this.direccion,
    this.ubicacion_mapa,
    this.fecha_nacimiento,
    this.edad,
    this.lugar_nacimiento,
    this.cedula_numero,
    this.tiene_casa_propia,
    this.tiene_vehiculo,
    this.tipo_vehiculo,
    this.es_casado,
    this.cantidad_hijos,
    this.ultimo_trabajo,
    this.motivo_salida_ultimo_trabajo,
    this.fecha_ingreso_empresa,
    this.salario_mensual,
    this.beneficios,
    this.es_tecnico_con_licencia,
    this.numero_licencia,
    this.foto_perfil_url,
    this.cedula_foto_url,
    this.carta_ultimo_trabajo_url,
    required this.estado,
    required this.created_at,
    required this.updated_at,
  });

  static String _toString(dynamic v, {String fallback = ''}) {
    if (v == null) return fallback;
    return v.toString();
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static bool? _toBool(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v;
    final s = v.toString().toLowerCase().trim();
    if (s == 'true' || s == '1' || s == 'yes' || s == 'si') return true;
    if (s == 'false' || s == '0' || s == 'no') return false;
    return null;
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    final s = v.toString().trim().replaceAll(',', '.');
    return double.tryParse(s);
  }

  static DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      id: _toString(json['id']),
      nombre_completo: _toString(json['nombre_completo']),
      email: _toString(json['email']),
      rol: _toString(json['rol']),
      posicion: json['posicion']?.toString(),
      telefono: json['telefono']?.toString(),
      direccion: json['direccion']?.toString(),
      ubicacion_mapa: json['ubicacion_mapa']?.toString(),
      fecha_nacimiento: _toDate(json['fecha_nacimiento']),
      edad: _toInt(json['edad']),
      lugar_nacimiento: json['lugar_nacimiento']?.toString(),
      cedula_numero: json['cedula_numero']?.toString(),
      tiene_casa_propia: _toBool(json['tiene_casa_propia']),
      tiene_vehiculo: _toBool(json['tiene_vehiculo']),
      tipo_vehiculo: json['tipo_vehiculo']?.toString(),
      es_casado: _toBool(json['es_casado']),
      cantidad_hijos: _toInt(json['cantidad_hijos']),
      ultimo_trabajo: json['ultimo_trabajo']?.toString(),
      motivo_salida_ultimo_trabajo: json['motivo_salida_ultimo_trabajo']
          ?.toString(),
      fecha_ingreso_empresa: _toDate(json['fecha_ingreso_empresa']),
      salario_mensual: _toDouble(json['salario_mensual']),
      beneficios: json['beneficios']?.toString(),
      es_tecnico_con_licencia: _toBool(json['es_tecnico_con_licencia']),
      numero_licencia: json['numero_licencia']?.toString(),
      foto_perfil_url: json['foto_perfil_url']?.toString(),
      cedula_foto_url: json['cedula_foto_url']?.toString(),
      carta_ultimo_trabajo_url: json['carta_ultimo_trabajo_url']?.toString(),
      estado: _toString(json['estado'], fallback: 'activo'),
      created_at: _toDate(json['created_at']) ?? DateTime.now(),
      updated_at: _toDate(json['updated_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre_completo': nombre_completo,
      'email': email,
      'rol': rol,
      'posicion': posicion,
      'telefono': telefono,
      'direccion': direccion,
      'ubicacion_mapa': ubicacion_mapa,
      'fecha_nacimiento': fecha_nacimiento?.toIso8601String(),
      'edad': edad,
      'lugar_nacimiento': lugar_nacimiento,
      'cedula_numero': cedula_numero,
      'tiene_casa_propia': tiene_casa_propia,
      'tiene_vehiculo': tiene_vehiculo,
      'tipo_vehiculo': tipo_vehiculo,
      'es_casado': es_casado,
      'cantidad_hijos': cantidad_hijos,
      'ultimo_trabajo': ultimo_trabajo,
      'motivo_salida_ultimo_trabajo': motivo_salida_ultimo_trabajo,
      'fecha_ingreso_empresa': fecha_ingreso_empresa?.toIso8601String(),
      'salario_mensual': salario_mensual,
      'beneficios': beneficios,
      'es_tecnico_con_licencia': es_tecnico_con_licencia,
      'numero_licencia': numero_licencia,
      'foto_perfil_url': foto_perfil_url,
      'cedula_foto_url': cedula_foto_url,
      'carta_ultimo_trabajo_url': carta_ultimo_trabajo_url,
      'estado': estado,
      'created_at': created_at.toIso8601String(),
      'updated_at': updated_at.toIso8601String(),
    };
  }

  UsuarioModel copyWith({
    String? id,
    String? nombre_completo,
    String? email,
    String? rol,
    String? posicion,
    String? telefono,
    String? direccion,
    String? ubicacion_mapa,
    DateTime? fecha_nacimiento,
    int? edad,
    String? lugar_nacimiento,
    String? cedula_numero,
    bool? tiene_casa_propia,
    bool? tiene_vehiculo,
    String? tipo_vehiculo,
    bool? es_casado,
    int? cantidad_hijos,
    String? ultimo_trabajo,
    String? motivo_salida_ultimo_trabajo,
    DateTime? fecha_ingreso_empresa,
    Decimal? salario_mensual,
    String? beneficios,
    bool? es_tecnico_con_licencia,
    String? numero_licencia,
    String? foto_perfil_url,
    String? cedula_foto_url,
    String? carta_ultimo_trabajo_url,
    String? estado,
    DateTime? created_at,
    DateTime? updated_at,
  }) {
    return UsuarioModel(
      id: id ?? this.id,
      nombre_completo: nombre_completo ?? this.nombre_completo,
      email: email ?? this.email,
      rol: rol ?? this.rol,
      posicion: posicion ?? this.posicion,
      telefono: telefono ?? this.telefono,
      direccion: direccion ?? this.direccion,
      ubicacion_mapa: ubicacion_mapa ?? this.ubicacion_mapa,
      fecha_nacimiento: fecha_nacimiento ?? this.fecha_nacimiento,
      edad: edad ?? this.edad,
      lugar_nacimiento: lugar_nacimiento ?? this.lugar_nacimiento,
      cedula_numero: cedula_numero ?? this.cedula_numero,
      tiene_casa_propia: tiene_casa_propia ?? this.tiene_casa_propia,
      tiene_vehiculo: tiene_vehiculo ?? this.tiene_vehiculo,
      tipo_vehiculo: tipo_vehiculo ?? this.tipo_vehiculo,
      es_casado: es_casado ?? this.es_casado,
      cantidad_hijos: cantidad_hijos ?? this.cantidad_hijos,
      ultimo_trabajo: ultimo_trabajo ?? this.ultimo_trabajo,
      motivo_salida_ultimo_trabajo:
          motivo_salida_ultimo_trabajo ?? this.motivo_salida_ultimo_trabajo,
      fecha_ingreso_empresa:
          fecha_ingreso_empresa ?? this.fecha_ingreso_empresa,
      salario_mensual: salario_mensual ?? this.salario_mensual,
      beneficios: beneficios ?? this.beneficios,
      es_tecnico_con_licencia:
          es_tecnico_con_licencia ?? this.es_tecnico_con_licencia,
      numero_licencia: numero_licencia ?? this.numero_licencia,
      foto_perfil_url: foto_perfil_url ?? this.foto_perfil_url,
      cedula_foto_url: cedula_foto_url ?? this.cedula_foto_url,
      carta_ultimo_trabajo_url:
          carta_ultimo_trabajo_url ?? this.carta_ultimo_trabajo_url,
      estado: estado ?? this.estado,
      created_at: created_at ?? this.created_at,
      updated_at: updated_at ?? this.updated_at,
    );
  }
}

/// Tipo ficticio para decimales (usar double en Flutter)
typedef Decimal = double;
