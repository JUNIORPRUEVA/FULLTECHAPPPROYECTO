import 'package:flutter/material.dart';

import '../../../core/widgets/module_page.dart';
import '../models/presupuesto.dart';
import 'presupuesto_detail_screen.dart';

class PresupuestoListScreen extends StatefulWidget {
  const PresupuestoListScreen({super.key});

  @override
  State<PresupuestoListScreen> createState() => _PresupuestoListScreenState();
}

class _PresupuestoListScreenState extends State<PresupuestoListScreen> {
  final _items = <Presupuesto>[
    const Presupuesto(id: '1', numero: 'P-0001', cliente: 'Juan Pérez', monto: 25000, estado: 'pendiente'),
    const Presupuesto(id: '2', numero: 'P-0002', cliente: 'María Gómez', monto: 12000, estado: 'aprobado'),
  ];

  @override
  Widget build(BuildContext context) {
    return ModulePage(
      title: 'Presupuesto',
      actions: [
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PresupuestoDetailScreen()),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Nuevo'),
        ),
      ],
      child: Card(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Número')),
              DataColumn(label: Text('Cliente')),
              DataColumn(label: Text('Monto')),
              DataColumn(label: Text('Estado')),
            ],
            rows: [
              for (final p in _items)
                DataRow(
                  onSelectChanged: (_) {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => PresupuestoDetailScreen(presupuestoId: p.id)),
                    );
                  },
                  cells: [
                    DataCell(Text(p.numero)),
                    DataCell(Text(p.cliente)),
                    DataCell(Text(p.monto.toStringAsFixed(2))),
                    DataCell(Text(p.estado)),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
