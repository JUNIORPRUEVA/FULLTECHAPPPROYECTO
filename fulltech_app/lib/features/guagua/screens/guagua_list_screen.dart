import 'package:flutter/material.dart';

import '../../../core/widgets/module_page.dart';
import 'guagua_detail_screen.dart';

class GuaguaListScreen extends StatelessWidget {
  const GuaguaListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ModulePage(
      title: 'Guagua (Gestión vehículos)',
      actions: [
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GuaguaDetailScreen()));
          },
          icon: const Icon(Icons.add),
          label: const Text('Nuevo'),
        ),
      ],
      child: const Card(
        child: Center(
          child: Text('TODO: Lista de vehículos, asignaciones y estado.'),
        ),
      ),
    );
  }
}
