import 'package:flutter/material.dart';

class NominaDetailScreen extends StatelessWidget {
  final String empleadoNombre;

  const NominaDetailScreen({
    super.key,
    required this.empleadoNombre,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de empleado')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Text('TODO: Editar datos de nómina para $empleadoNombre'),
      ),
    );
  }
}
