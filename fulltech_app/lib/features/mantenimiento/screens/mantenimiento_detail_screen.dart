import 'package:flutter/material.dart';

class MantenimientoDetailScreen extends StatelessWidget {
  const MantenimientoDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mantenimiento')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text('TODO: Detalle/edición de mantenimiento.'),
      ),
    );
  }
}
