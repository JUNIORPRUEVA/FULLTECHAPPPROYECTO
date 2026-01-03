import 'package:flutter/material.dart';

import '../../../core/widgets/module_page.dart';
import 'ponchado_detail_screen.dart';

class PonchadoListScreen extends StatelessWidget {
  const PonchadoListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ModulePage(
      title: 'Ponchado (Control asistencia)',
      actions: [
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PonchadoDetailScreen()));
          },
          icon: const Icon(Icons.add),
          label: const Text('Nuevo'),
        ),
      ],
      child: const Card(
        child: Center(
          child: Text('TODO: Lista de entradas/salidas por empleado.'),
        ),
      ),
    );
  }
}
