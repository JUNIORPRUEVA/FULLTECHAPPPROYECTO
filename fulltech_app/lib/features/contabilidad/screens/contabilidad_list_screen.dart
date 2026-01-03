import 'package:flutter/material.dart';

import '../../../core/widgets/module_page.dart';
import 'contabilidad_detail_screen.dart';

class ContabilidadListScreen extends StatelessWidget {
  const ContabilidadListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ModulePage(
      title: 'Contabilidad',
      actions: [
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ContabilidadDetailScreen()));
          },
          icon: const Icon(Icons.add),
          label: const Text('Nuevo'),
        ),
      ],
      child: const Card(
        child: Center(
          child: Text('TODO: Lista de registros contables.'),
        ),
      ),
    );
  }
}
