import 'package:flutter/material.dart';

class CrmDetailScreen extends StatelessWidget {
  final String clienteNombre;

  const CrmDetailScreen({
    super.key,
    required this.clienteNombre,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de cliente')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              clienteNombre,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            const Text('TODO: Formulario de edición (teléfono, estado, notas, etc.).'),
            const SizedBox(height: 12),
            const Text('TODO: Integración con historial de chat/WhatsApp.'),
          ],
        ),
      ),
    );
  }
}
