import 'package:flutter/material.dart';

class PonchadoDetailScreen extends StatelessWidget {
  const PonchadoDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ponchado')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text('TODO: Detalle/edición de registro de asistencia.'),
      ),
    );
  }
}
