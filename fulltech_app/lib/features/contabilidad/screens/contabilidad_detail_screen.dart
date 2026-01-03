import 'package:flutter/material.dart';

class ContabilidadDetailScreen extends StatelessWidget {
  const ContabilidadDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contabilidad')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text('TODO: Detalle/edición de asiento/registro contable.'),
      ),
    );
  }
}
