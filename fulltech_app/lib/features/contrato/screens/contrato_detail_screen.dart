import 'package:flutter/material.dart';

class ContratoDetailScreen extends StatelessWidget {
  const ContratoDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contrato')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text('TODO: Detalle/edición de contrato.'),
      ),
    );
  }
}
