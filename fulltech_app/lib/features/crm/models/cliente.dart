class Cliente {
  final String id;
  final String nombre;
  final String telefono;
  final String estado; // pendiente, interesado, compro
  final String? ultimoMensaje;
  final DateTime? ultimaInteraccion;

  const Cliente({
    required this.id,
    required this.nombre,
    required this.telefono,
    required this.estado,
    this.ultimoMensaje,
    this.ultimaInteraccion,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      telefono: json['telefono'] as String,
      estado: json['estado'] as String,
      ultimoMensaje: json['ultimo_mensaje'] as String?,
      ultimaInteraccion: json['ultima_interaccion'] != null
          ? DateTime.tryParse(json['ultima_interaccion'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'telefono': telefono,
      'estado': estado,
      'ultimo_mensaje': ultimoMensaje,
      'ultima_interaccion': ultimaInteraccion?.toIso8601String(),
    };
  }
}
