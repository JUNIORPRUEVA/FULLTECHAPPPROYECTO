import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/module_page.dart';
import '../../state/pos_providers.dart';
import '../../models/pos_models.dart';

class PosReportsPage extends ConsumerStatefulWidget {
  const PosReportsPage({super.key});

  @override
  ConsumerState<PosReportsPage> createState() => _PosReportsPageState();
}

class _PosReportsPageState extends ConsumerState<PosReportsPage> {
  Future<({double total, int count, double avgTicket})> _salesSummary() async {
    final repo = ref.read(posRepositoryProvider);
    return repo.salesSummary();
  }

  Future<List<Map<String, dynamic>>> _topProducts() async {
    final repo = ref.read(posRepositoryProvider);
    return repo.topProducts();
  }

  @override
  Widget build(BuildContext context) {
    return ModulePage(
      title: 'POS / Reportes',
      child: ListView(
        children: [
          FutureBuilder(
            future: _salesSummary(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Card(child: Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()));
              }
              if (snap.hasError) {
                return Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('Error: ${snap.error}')));
              }

              final s = snap.data;
              if (s == null) return const SizedBox.shrink();

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Ventas', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('Total: ${money(s.total)}'),
                      Text('Cantidad: ${s.count}'),
                      Text('Ticket promedio: ${money(s.avgTicket)}'),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          FutureBuilder(
            future: _topProducts(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Card(child: Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()));
              }
              if (snap.hasError) {
                return Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('Error: ${snap.error}')));
              }

              final rows = snap.data ?? const [];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Top productos', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      if (rows.isEmpty)
                        const Text('Sin datos')
                      else
                        ...rows.take(15).map((r) {
                          final name = (r['product_name'] ?? r['nombre'] ?? '—').toString();
                          final qty = (r['qty'] as num?)?.toDouble() ?? 0;
                          final total = (r['total'] as num?)?.toDouble() ?? 0;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis)),
                                Text(qty.toStringAsFixed(2)),
                                const SizedBox(width: 12),
                                Text(money(total)),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
