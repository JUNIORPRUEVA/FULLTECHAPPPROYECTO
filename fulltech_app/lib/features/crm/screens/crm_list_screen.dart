import 'package:flutter/material.dart';

import '../../../core/widgets/module_page.dart';
import '../models/cliente.dart';
import 'crm_detail_screen.dart';

class CrmListScreen extends StatefulWidget {
  const CrmListScreen({super.key});

  @override
  State<CrmListScreen> createState() => _CrmListScreenState();
}

class _CrmListScreenState extends State<CrmListScreen> {
  final _searchCtrl = TextEditingController();
  String _estado = 'todos';

  // Demo data (local-only). TODO: Load from local DB + sync with backend.
  final _items = <Cliente>[
    Cliente(
      id: '1',
      nombre: 'Juan Pérez',
      telefono: '8090000001',
      estado: 'pendiente',
      ultimoMensaje: 'Hola, quiero cotizar...',
      ultimaInteraccion: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Cliente(
      id: '2',
      nombre: 'María Gómez',
      telefono: '8290000002',
      estado: 'interesado',
      ultimoMensaje: '¿Tienen disponibilidad esta semana?',
      ultimaInteraccion: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Cliente> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _items.where((c) {
      final matchEstado = _estado == 'todos' ? true : c.estado == _estado;
      final matchQuery = q.isEmpty
          ? true
          : c.nombre.toLowerCase().contains(q) || c.telefono.toLowerCase().contains(q);
      return matchEstado && matchQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ModulePage(
      title: 'CRM',
      child: Column(
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 320,
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Buscar por nombre o teléfono',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String>(
                  value: _estado,
                  items: const [
                    DropdownMenuItem(value: 'todos', child: Text('Todos')),
                    DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
                    DropdownMenuItem(value: 'interesado', child: Text('Interesado')),
                    DropdownMenuItem(value: 'compro', child: Text('Compró')),
                  ],
                  onChanged: (v) => setState(() => _estado = v ?? 'todos'),
                  decoration: const InputDecoration(
                    labelText: 'Estado',
                    prefixIcon: Icon(Icons.filter_alt_outlined),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Card(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Nombre')),
                    DataColumn(label: Text('Teléfono')),
                    DataColumn(label: Text('Estado')),
                    DataColumn(label: Text('Último mensaje')),
                    DataColumn(label: Text('Última interacción')),
                  ],
                  rows: [
                    for (final c in _filtered)
                      DataRow(
                        onSelectChanged: (_) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CrmDetailScreen(clienteNombre: c.nombre),
                            ),
                          );
                        },
                        cells: [
                          DataCell(Text(c.nombre)),
                          DataCell(Text(c.telefono)),
                          DataCell(Text(c.estado)),
                          DataCell(Text(c.ultimoMensaje ?? '')),
                          DataCell(Text(c.ultimaInteraccion?.toString() ?? '')),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('TODO: Conectar con backend /clientes y cola de sincronización.'),
          ),
        ],
      ),
    );
  }
}
