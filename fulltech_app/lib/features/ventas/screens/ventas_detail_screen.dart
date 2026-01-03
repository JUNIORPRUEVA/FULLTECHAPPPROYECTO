import 'package:flutter/material.dart';

class VentasDetailScreen extends StatelessWidget {
  const VentasDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de venta')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text('TODO: Crear/editar venta. Integrar con backend /ventas.'),
      ),
    );
  }
}
