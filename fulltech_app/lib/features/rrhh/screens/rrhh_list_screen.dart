import 'package:flutter/material.dart';

import '../../../core/widgets/module_page.dart';
import 'rrhh_detail_screen.dart';

class RrhhListScreen extends StatelessWidget {
  const RrhhListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ModulePage(
      title: 'RRHH',
      actions: [
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RrhhDetailScreen()));
          },
          icon: const Icon(Icons.add),
          label: const Text('Nuevo'),
        ),
      ],
      child: const Card(
        child: Center(
          child: Text('TODO: Lista de procesos RRHH (empleados, expedientes, etc.).'),
        ),
      ),
    );
  }
}
