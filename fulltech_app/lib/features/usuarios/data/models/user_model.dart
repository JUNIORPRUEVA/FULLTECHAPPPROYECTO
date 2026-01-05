class UserModel {
  final String id;
  final String empresaId;
  final String email;
  final String nombre;
  final String rol;
  final String? posicion;
  final String? areaManeja;

  final String? telefono;
  final String? direccion;
  final String? ubicacionMapa;

  final DateTime? fechaNacimiento;
  final int? edad;
  final String? cedulaNumero;
  final String? lugarNacimiento;

  final bool esCasado;
  final int cantidadHijos;
  final bool tieneCasa;
  final bool tieneVehiculo;
  final String? tipoVehiculo;
  final String? placa;

  final DateTime? fechaIngreso;
  final num? salarioMensual;
  final String? beneficios;

  /// Meta de ventas (quincenal), usada por el módulo de Ventas.
  final num? metaVentas;

  final String? licenciaConducirNumero;
  final DateTime? licenciaConducirVencimiento;

  final String? fotoPerfilUrl;
  final String? cedulaFrontalUrl;
  final String? cedulaPosteriorUrl;
  final String? licenciaConducirUrl;
  final String? cartaTrabajoUrl;
  final String? curriculumVitaeUrl;
  final List<String> otrosDocumentos;

  final String estado;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.id,
    required this.empresaId,
    required this.email,
    required this.nombre,
    required this.rol,
    required this.estado,
    this.posicion,
    this.areaManeja,
    this.telefono,
    this.direccion,
    this.ubicacionMapa,
    this.fechaNacimiento,
    this.edad,
    this.cedulaNumero,
    this.lugarNacimiento,
    required this.esCasado,
    required this.cantidadHijos,
    required this.tieneCasa,
    required this.tieneVehiculo,
    this.tipoVehiculo,
    this.placa,
    this.fechaIngreso,
    this.salarioMensual,
    this.beneficios,
    this.metaVentas,
    this.licenciaConducirNumero,
    this.licenciaConducirVencimiento,
    this.fotoPerfilUrl,
    this.cedulaFrontalUrl,
    this.cedulaPosteriorUrl,
    this.licenciaConducirUrl,
    this.cartaTrabajoUrl,
    this.curriculumVitaeUrl,
    required this.otrosDocumentos,
    this.createdAt,
    this.updatedAt,
  });

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) {
      final t = v.trim();
      if (t.isEmpty) return null;
      return DateTime.tryParse(t);
    }
    return null;
  }

  static String? _str(dynamic v) {
    if (v == null) return null;
    if (v is String) {
      final t = v.trim();
      return t.isEmpty ? null : t;
    }
    return v.toString();
  }

  static bool _bool(dynamic v, {bool fallback = false}) {
    if (v is bool) return v;
    if (v is String) {
      final t = v.trim().toLowerCase();
      if (t == 'true') return true;
      if (t == 'false') return false;
    }
    return fallback;
  }

  static int _int(dynamic v, {int fallback = 0}) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return fallback;
  }

  static List<String> _stringList(dynamic v) {
    if (v is List) {
      return v.map((e) => _str(e)).whereType<String>().toList();
    }
    return const [];
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final otros = _stringList(json['otros_documentos'] ?? json['otros_documentos_url']);

    num? readMetaVentas() {
      final direct = json['meta_ventas'];
      if (direct is num) return direct;
      if (direct is String) return num.tryParse(direct);

      final metadata = json['metadata'];
      if (metadata is Map) {
        final mv = metadata['meta_ventas'];
        if (mv is num) return mv;
        if (mv is String) return num.tryParse(mv);
      }
      return null;
    }

    return UserModel(
      id: json['id'] as String,
      empresaId: (json['empresa_id'] ?? json['empresaId']) as String,
      email: json['email'] as String,
      nombre: (json['nombre_completo'] ?? json['nombre'] ?? json['name'] ?? json['nombreCompleto']) as String,
      rol: (json['rol'] ?? json['role']) as String,
      posicion: _str(json['posicion']),
      areaManeja: _str(json['area_maneja']),

      telefono: _str(json['telefono']),
      direccion: _str(json['direccion']),
      ubicacionMapa: _str(json['ubicacion_mapa']),

      fechaNacimiento: _parseDate(json['fecha_nacimiento']),
      edad: (json['edad'] as num?)?.toInt(),
      cedulaNumero: _str(json['cedula_numero']),
      lugarNacimiento: _str(json['lugar_nacimiento']),

      esCasado: _bool(json['es_casado'], fallback: false),
      cantidadHijos: _int(json['cantidad_hijos'], fallback: 0),
      tieneCasa: _bool(json['tiene_casa'] ?? json['tiene_casa_propia'], fallback: false),
      tieneVehiculo: _bool(json['tiene_vehiculo'], fallback: false),
      tipoVehiculo: _str(json['tipo_vehiculo']),
      placa: _str(json['placa'] ?? json['placa_vehiculo']),

      fechaIngreso: _parseDate(json['fecha_ingreso'] ?? json['fecha_ingreso_empresa']),
      salarioMensual: json['salario_mensual'] as num?,
      beneficios: _str(json['beneficios']),
      metaVentas: readMetaVentas(),

      licenciaConducirNumero: _str(json['licencia_conducir_numero']),
      licenciaConducirVencimiento: _parseDate(json['licencia_conducir_fecha_vencimiento']),

      fotoPerfilUrl: _str(json['foto_perfil_url']),
      cedulaFrontalUrl: _str(json['cedula_frontal_url'] ?? json['cedula_foto_frontal_url'] ?? json['cedula_foto_url']),
      cedulaPosteriorUrl: _str(json['cedula_posterior_url'] ?? json['cedula_foto_posterior_url']),
      licenciaConducirUrl: _str(json['licencia_conducir_url'] ?? json['licencia_conducir_foto_url']),
      cartaTrabajoUrl: _str(json['carta_trabajo_url'] ?? json['carta_ultimo_trabajo_url']),
      curriculumVitaeUrl: _str(json['curriculum_vitae_url']),
      otrosDocumentos: otros,

      estado: (json['estado'] ?? 'activo') as String,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }
}

class UserSummary {
  final String id;
  final String email;
  final String nombre;
  final String rol;
  final String estado;
  final String? telefono;
  final DateTime? fechaIngreso;
  final String? fotoPerfilUrl;

  const UserSummary({
    required this.id,
    required this.email,
    required this.nombre,
    required this.rol,
    required this.estado,
    this.telefono,
    this.fechaIngreso,
    this.fotoPerfilUrl,
  });

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  factory UserSummary.fromJson(Map<String, dynamic> json) {
    return UserSummary(
      id: json['id'] as String,
      email: (json['email'] ?? '') as String,
      nombre: (json['nombre_completo'] ?? json['name'] ?? '') as String,
      rol: (json['rol'] ?? json['role'] ?? '') as String,
      estado: (json['estado'] ?? 'activo') as String,
      telefono: json['telefono'] as String?,
      fechaIngreso: _parseDate(json['fecha_ingreso_empresa'] ?? json['fecha_ingreso']),
      fotoPerfilUrl: json['foto_perfil_url'] as String?,
    );
  }
}

class UsersPage {
  final int page;
  final int pageSize;
  final int total;
  final List<UserSummary> items;

  const UsersPage({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.items,
  });
}
