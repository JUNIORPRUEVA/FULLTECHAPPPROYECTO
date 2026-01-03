import 'package:flutter/material.dart';

import '../../../core/widgets/module_page.dart';
import '../models/levantamiento.dart';
import 'operaciones_detail_screen.dart';

class OperacionesListScreen extends StatefulWidget {
  const OperacionesListScreen({super.key});

  @override
  State<OperacionesListScreen> createState() => _OperacionesListScreenState();
}

class _OperacionesListScreenState extends State<OperacionesListScreen> {
  final _clienteCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _tecnicoCtrl = TextEditingController();

  final _items = <Levantamiento>[
    Levantamiento(
      id: '1',
      cliente: 'Juan Pérez',
      direccion: 'Santo Domingo',
      fecha: DateTime.now().add(const Duration(days: 1)),
      tecnico: 'Carlos',
    ),
  ];

  @override
  void dispose() {
    _clienteCtrl.dispose();
    _direccionCtrl.dispose();
    _tecnicoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ModulePage(
      title: 'Operaciones / Levantamiento',
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Registrar levantamiento',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: 260,
                        child: TextField(
                          controller: _clienteCtrl,
                          decoration: const InputDecoration(labelText: 'Cliente'),
                        ),
                      ),
                      SizedBox(
                        width: 320,
                        child: TextField(
                          controller: _direccionCtrl,
                          decoration: const InputDecoration(labelText: 'Dirección'),
                        ),
                      ),
                      SizedBox(
                        width: 240,
                        child: TextField(
                          controller: _tecnicoCtrl,
                          decoration: const InputDecoration(labelText: 'Técnico asignado'),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () {
                          // TODO: Guardar local + encolar sync.
                          setState(() {
                            _items.add(
                              Levantamiento(
                                id: DateTime.now().millisecondsSinceEpoch.toString(),
                                cliente: _clienteCtrl.text,
                                direccion: _direccionCtrl.text,
                                fecha: DateTime.now(),
                                tecnico: _tecnicoCtrl.text,
                              ),
                            );
                          });
                          _clienteCtrl.clear();
                          _direccionCtrl.clear();
                          _tecnicoCtrl.clear();
                        },
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Guardar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Card(
              child: ListView.separated(
                itemCount: _items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final it = _items[i];
                  return ListTile(
                    leading: const Icon(Icons.assignment_outlined),
                    title: Text(it.cliente),
                    subtitle: Text('${it.direccion} · ${it.tecnico}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => OperacionesDetailScreen(title: 'Levantamiento - ${it.cliente}'),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('TODO: Agregar sección de Instalaciones programadas (pendiente/en proceso/finalizada).'),
          ),
        ],
      ),
    );
  }
}
