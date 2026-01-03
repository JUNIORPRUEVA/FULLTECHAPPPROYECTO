import 'package:flutter/material.dart';

import '../../../core/widgets/module_page.dart';
import 'garantia_detail_screen.dart';

class GarantiaListScreen extends StatelessWidget {
  const GarantiaListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ModulePage(
      title: 'Garantía',
      actions: [
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GarantiaDetailScreen()));
          },
          icon: const Icon(Icons.add),
          label: const Text('Nuevo caso'),
        ),
      ],
      child: const Card(
        child: Center(
          child: Text('TODO: Lista de casos de garantía (pendiente/en proceso/cerrado).'),
        ),
      ),
    );
  }
}
