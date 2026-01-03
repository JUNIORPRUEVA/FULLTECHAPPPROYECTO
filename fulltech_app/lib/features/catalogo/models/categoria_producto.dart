class CategoriaProducto {
  final String id;
  final String nombre;
  final String? descripcion;
  final bool isActive;

  const CategoriaProducto({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.isActive,
  });

  factory CategoriaProducto.fromJson(Map<String, dynamic> json) {
    return CategoriaProducto(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      isActive: (json['is_active'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'is_active': isActive,
    };
  }
}
