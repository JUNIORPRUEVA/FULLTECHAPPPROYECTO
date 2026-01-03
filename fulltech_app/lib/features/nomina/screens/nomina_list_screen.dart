import 'package:flutter/material.dart';

import '../../../core/widgets/module_page.dart';
import '../models/empleado.dart';
import 'nomina_detail_screen.dart';

class NominaListScreen extends StatelessWidget {
  const NominaListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <Empleado>[
      const Empleado(id: '1', nombre: 'Carlos Martínez', salarioBase: 35000),
      const Empleado(id: '2', nombre: 'Ana López', salarioBase: 28000),
    ];

    return ModulePage(
      title: 'Nómina',
      child: Card(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Empleado')),
              DataColumn(label: Text('Salario base')),
            ],
            rows: [
              for (final e in items)
                DataRow(
                  onSelectChanged: (_) {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => NominaDetailScreen(empleadoNombre: e.nombre)),
                    );
                  },
                  cells: [
                    DataCell(Text(e.nombre)),
                    DataCell(Text(e.salarioBase.toStringAsFixed(2))),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
