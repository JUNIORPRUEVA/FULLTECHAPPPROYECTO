import 'package:flutter/material.dart';

import '../../../core/widgets/module_page.dart';
import 'contrato_detail_screen.dart';

class ContratoListScreen extends StatelessWidget {
  const ContratoListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ModulePage(
      title: 'Contrato',
      actions: [
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ContratoDetailScreen()));
          },
          icon: const Icon(Icons.add),
          label: const Text('Nuevo'),
        ),
      ],
      child: const Card(
        child: Center(
          child: Text('TODO: Lista de contratos.'),
        ),
      ),
    );
  }
}
