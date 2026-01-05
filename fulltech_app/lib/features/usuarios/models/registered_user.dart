class RegisteredUser {
  final String id;
  final String empresaId;
  final String email;
  final String nombreCompleto;
  final String rol;
  final String? posicion;
  final String telefono;
  final String direccion;
  final String? ubicacionMapa;

  final DateTime? fechaNacimiento;
  final int? edad;
  final String? lugarNacimiento;
  final String? cedulaNumero;

  final bool? tieneCasaPropia;
  final bool? tieneVehiculo;
  final String? tipoVehiculo;
  final bool? esCasado;
  final int? cantidadHijos;

  final String? ultimoTrabajo;
  final String? motivoSalidaUltimoTrabajo;

  final DateTime? fechaIngresoEmpresa;
  final num? salarioMensual;
  final String? beneficios;

  final bool? esTecnicoConLicencia;
  final String? numeroLicencia;

  final String? fotoPerfilUrl;
  final String? cedulaFotoUrl;
  final String? cartaUltimoTrabajoUrl;

  final String? estado;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Meta de ventas (quincenal). Puede venir como `meta_ventas` o dentro de `metadata.meta_ventas`.
  final num? metaVentas;

  const RegisteredUser({
    required this.id,
    required this.empresaId,
    required this.email,
    required this.nombreCompleto,
    required this.rol,
    required this.telefono,
    required this.direccion,
    this.posicion,
    this.ubicacionMapa,
    this.fechaNacimiento,
    this.edad,
    this.lugarNacimiento,
    this.cedulaNumero,
    this.tieneCasaPropia,
    this.tieneVehiculo,
    this.tipoVehiculo,
    this.esCasado,
    this.cantidadHijos,
    this.ultimoTrabajo,
    this.motivoSalidaUltimoTrabajo,
    this.fechaIngresoEmpresa,
    this.salarioMensual,
    this.beneficios,
    this.esTecnicoConLicencia,
    this.numeroLicencia,
    this.fotoPerfilUrl,
    this.cedulaFotoUrl,
    this.cartaUltimoTrabajoUrl,
    this.estado,
    this.createdAt,
    this.updatedAt,
    this.metaVentas,
  });

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) {
      final trimmed = v.trim();
      if (trimmed.isEmpty) return null;
      return DateTime.tryParse(trimmed);
    }
    return null;
  }

  factory RegisteredUser.fromJson(Map<String, dynamic> json) {
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

    return RegisteredUser(
      id: json['id'] as String,
      empresaId: (json['empresa_id'] ?? json['empresaId']) as String,
      email: json['email'] as String,
      nombreCompleto: (json['nombre_completo'] ?? json['nombreCompleto'] ?? json['name']) as String,
      rol: (json['rol'] ?? json['role']) as String,
      posicion: json['posicion'] as String?,
      telefono: (json['telefono'] ?? '') as String,
      direccion: (json['direccion'] ?? '') as String,
      ubicacionMapa: json['ubicacion_mapa'] as String?,
      fechaNacimiento: _parseDate(json['fecha_nacimiento']),
      edad: (json['edad'] as num?)?.toInt(),
      lugarNacimiento: json['lugar_nacimiento'] as String?,
      cedulaNumero: json['cedula_numero'] as String?,
      tieneCasaPropia: json['tiene_casa_propia'] as bool?,
      tieneVehiculo: json['tiene_vehiculo'] as bool?,
      tipoVehiculo: json['tipo_vehiculo'] as String?,
      esCasado: json['es_casado'] as bool?,
      cantidadHijos: (json['cantidad_hijos'] as num?)?.toInt(),
      ultimoTrabajo: json['ultimo_trabajo'] as String?,
      motivoSalidaUltimoTrabajo: json['motivo_salida_ultimo_trabajo'] as String?,
      fechaIngresoEmpresa: _parseDate(json['fecha_ingreso_empresa']),
      salarioMensual: json['salario_mensual'] as num?,
      beneficios: json['beneficios'] as String?,
      esTecnicoConLicencia: json['es_tecnico_con_licencia'] as bool?,
      numeroLicencia: json['numero_licencia'] as String?,
      fotoPerfilUrl: json['foto_perfil_url'] as String?,
      cedulaFotoUrl: json['cedula_foto_url'] as String?,
      cartaUltimoTrabajoUrl: json['carta_ultimo_trabajo_url'] as String?,
      estado: json['estado'] as String?,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      metaVentas: readMetaVentas(),
    );
  }
}

class RegisteredUserSummary {
  final String id;
  final String empresaId;
  final String email;
  final String nombreCompleto;
  final String rol;
  final String? posicion;
  final String telefono;
  final String estado;
  final String? fotoPerfilUrl;
  final DateTime? updatedAt;

  const RegisteredUserSummary({
    required this.id,
    required this.empresaId,
    required this.email,
    required this.nombreCompleto,
    required this.rol,
    required this.telefono,
    required this.estado,
    this.posicion,
    this.fotoPerfilUrl,
    this.updatedAt,
  });

  factory RegisteredUserSummary.fromJson(Map<String, dynamic> json) {
    return RegisteredUserSummary(
      id: json['id'] as String,
      empresaId: (json['empresa_id'] ?? json['empresaId']) as String,
      email: json['email'] as String,
      nombreCompleto: (json['nombre_completo'] ?? json['name']) as String,
      rol: (json['rol'] ?? json['role']) as String,
      posicion: json['posicion'] as String?,
      telefono: (json['telefono'] ?? '') as String,
      estado: (json['estado'] ?? 'activo') as String,
      fotoPerfilUrl: json['foto_perfil_url'] as String?,
      updatedAt: RegisteredUser._parseDate(json['updated_at']),
    );
  }
}

class UsersPage {
  final int page;
  final int pageSize;
  final int total;
  final List<RegisteredUserSummary> items;

  const UsersPage({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.items,
  });
}

class UserDocsUploadResult {
  final String? fotoPerfilUrl;
  final String? cedulaFotoUrl;
  final String? cartaUltimoTrabajoUrl;

  const UserDocsUploadResult({
    required this.fotoPerfilUrl,
    required this.cedulaFotoUrl,
    required this.cartaUltimoTrabajoUrl,
  });

  factory UserDocsUploadResult.fromJson(Map<String, dynamic> json) {
    return UserDocsUploadResult(
      fotoPerfilUrl: json['fotoPerfilUrl'] as String?,
      cedulaFotoUrl: json['cedulaFotoUrl'] as String?,
      cartaUltimoTrabajoUrl: json['cartaUltimoTrabajoUrl'] as String?,
    );
  }
}
