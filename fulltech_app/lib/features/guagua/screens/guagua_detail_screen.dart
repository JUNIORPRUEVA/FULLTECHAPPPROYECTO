import 'package:flutter/material.dart';

class GuaguaDetailScreen extends StatelessWidget {
  const GuaguaDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Guagua / Vehículo')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text('TODO: Detalle/edición de vehículo.'),
      ),
    );
  }
}
