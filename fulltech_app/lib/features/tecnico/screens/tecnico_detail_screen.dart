import 'package:flutter/material.dart';

class TecnicoDetailScreen extends StatelessWidget {
  const TecnicoDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Técnico')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text('TODO: Detalle/edición de técnico.'),
      ),
    );
  }
}
