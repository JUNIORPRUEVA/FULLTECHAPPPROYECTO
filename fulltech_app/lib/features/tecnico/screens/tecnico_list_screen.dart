import 'package:flutter/material.dart';

import '../../../core/widgets/module_page.dart';
import 'tecnico_detail_screen.dart';

class TecnicoListScreen extends StatelessWidget {
  const TecnicoListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ModulePage(
      title: 'Técnico',
      actions: [
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TecnicoDetailScreen()));
          },
          icon: const Icon(Icons.add),
          label: const Text('Nuevo'),
        ),
      ],
      child: const Card(
        child: Center(
          child: Text('TODO: Lista de técnicos (disponibilidad, asignaciones, etc.).'),
        ),
      ),
    );
  }
}
