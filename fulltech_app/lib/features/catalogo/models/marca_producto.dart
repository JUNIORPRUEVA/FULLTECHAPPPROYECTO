class MarcaProducto {
  final String id;
  final String nombre;

  const MarcaProducto({required this.id, required this.nombre});

  factory MarcaProducto.fromJson(Map<String, dynamic> json) {
    return MarcaProducto(
      id: (json['id'] ?? '').toString(),
      nombre: (json['nombre'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'nombre': nombre};
  }

  MarcaProducto copyWith({String? id, String? nombre}) {
    return MarcaProducto(id: id ?? this.id, nombre: nombre ?? this.nombre);
  }
}
