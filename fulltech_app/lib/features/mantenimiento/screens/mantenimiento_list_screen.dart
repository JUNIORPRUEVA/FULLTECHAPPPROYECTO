import 'package:flutter/material.dart';

import '../../../core/widgets/module_page.dart';
import 'mantenimiento_detail_screen.dart';

class MantenimientoListScreen extends StatelessWidget {
  const MantenimientoListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ModulePage(
      title: 'Mantenimiento',
      actions: [
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MantenimientoDetailScreen()));
          },
          icon: const Icon(Icons.add),
          label: const Text('Nuevo'),
        ),
      ],
      child: const Card(
        child: Center(
          child: Text('TODO: Lista de mantenimientos (activos, vencidos, etc.).'),
        ),
      ),
    );
  }
}
