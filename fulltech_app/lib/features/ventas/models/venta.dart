class Venta {
  final String id;
  final String clienteId;
  final String numero;
  final double monto;
  final String estado;

  const Venta({
    required this.id,
    required this.clienteId,
    required this.numero,
    required this.monto,
    required this.estado,
  });

  factory Venta.fromJson(Map<String, dynamic> json) {
    return Venta(
      id: json['id'] as String,
      clienteId: json['cliente_id'] as String,
      numero: json['numero'] as String,
      monto: (json['monto'] as num).toDouble(),
      estado: json['estado'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cliente_id': clienteId,
      'numero': numero,
      'monto': monto,
      'estado': estado,
    };
  }
}
