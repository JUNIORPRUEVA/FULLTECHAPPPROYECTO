import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/module_page.dart';
import '../data/models/payroll_models.dart';
import '../state/payroll_providers.dart';

class NominaListScreen extends ConsumerWidget {
  const NominaListScreen({super.key});

  String _halfLabel(PayrollHalf half) =>
      half == PayrollHalf.first ? '1–15' : '16–Fin';

  Future<void> _openCreateDialog(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    int year = now.year;
    int month = now.month;
    PayrollHalf half = now.day <= 15 ? PayrollHalf.first : PayrollHalf.second;

    final runId = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Nueva corrida quincenal'),
              content: SizedBox(
                width: 380,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Expanded(child: Text('Año')),
                        DropdownButton<int>(
                          value: year,
                          items: List.generate(5, (i) => now.year - 2 + i)
                              .map(
                                (y) => DropdownMenuItem(
                                  value: y,
                                  child: Text('$y'),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => year = v ?? year),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Expanded(child: Text('Mes')),
                        DropdownButton<int>(
                          value: month,
                          items: List.generate(12, (i) => i + 1)
                              .map(
                                (m) => DropdownMenuItem(
                                  value: m,
                                  child: Text(m.toString().padLeft(2, '0')),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => month = v ?? month),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Expanded(child: Text('Quincena')),
                        DropdownButton<PayrollHalf>(
                          value: half,
                          items: PayrollHalf.values
                              .map(
                                (h) => DropdownMenuItem(
                                  value: h,
                                  child: Text(_halfLabel(h)),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => half = v ?? half),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () async {
                    final id = await ref
                        .read(payrollRunsControllerProvider.notifier)
                        .createRun(year: year, month: month, half: half);
                    if (ctx.mounted) Navigator.of(ctx).pop(id);
                  },
                  child: const Text('Crear'),
                ),
              ],
            );
          },
        );
      },
    );

    if (runId != null && runId.trim().isNotEmpty) {
      if (!context.mounted) return;
      context.go('${AppRoutes.nomina}/runs/$runId');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(payrollRunsControllerProvider);

    return ModulePage(
      title: 'Nómina (Admin)',
      actions: [
        IconButton(
          tooltip: 'Refrescar',
          onPressed: () => ref
              .read(payrollRunsControllerProvider.notifier)
              .refresh(showLoading: false),
          icon: const Icon(Icons.refresh),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: () => _openCreateDialog(context, ref),
          icon: const Icon(Icons.add),
          label: const Text('Nueva corrida'),
        ),
      ],
      child: Card(
        child: Column(
          children: [
            if (state.loading) const LinearProgressIndicator(minHeight: 2),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  state.error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Período')),
                      DataColumn(label: Text('Estado')),
                      DataColumn(label: Text('Empleados')),
                      DataColumn(label: Text('Neto')),
                    ],
                    rows: [
                      for (final r in state.items)
                        DataRow(
                          onSelectChanged: (_) =>
                              context.go('${AppRoutes.nomina}/runs/${r.id}'),
                          cells: [
                            DataCell(
                              Text(
                                r.period == null
                                    ? r.id
                                    : '${r.period!.year}-${r.period!.month.toString().padLeft(2, '0')} (${_halfLabel(r.period!.half)})',
                              ),
                            ),
                            DataCell(Text(r.status.name.toUpperCase())),
                            DataCell(Text('${r.employeesCount ?? '-'}')),
                            DataCell(
                              Text((r.totals?.net ?? 0).toStringAsFixed(2)),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
