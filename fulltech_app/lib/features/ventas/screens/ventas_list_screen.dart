import 'package:flutter/material.dart';

import '../../../core/widgets/module_page.dart';
import 'ventas_detail_screen.dart';

class VentasListScreen extends StatelessWidget {
  const VentasListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ModulePage(
      title: 'Ventas',
      actions: [
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VentasDetailScreen()));
          },
          icon: const Icon(Icons.add),
          label: const Text('Nueva'),
        ),
      ],
      child: const Card(
        child: Center(
          child: Text('TODO: Tabla de ventas (número, cliente, monto, estado).'),
        ),
      ),
    );
  }
}
