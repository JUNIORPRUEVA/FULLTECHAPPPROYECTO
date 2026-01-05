import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/module_page.dart';
import '../data/models/payroll_models.dart';
import '../state/payroll_providers.dart';
import 'my_payroll_detail_screen.dart';

class MyPayrollScreen extends ConsumerWidget {
  const MyPayrollScreen({super.key});

  String _halfLabel(PayrollHalf half) =>
      half == PayrollHalf.first ? '1–15' : '16–Fin';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myPayrollControllerProvider);

    return ModulePage(
      title: 'Mis Nóminas',
      actions: [
        IconButton(
          tooltip: 'Refrescar',
          onPressed: () => ref
              .read(myPayrollControllerProvider.notifier)
              .refresh(showLoading: false),
          icon: const Icon(Icons.refresh),
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
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  if (state.notifications.isNotEmpty) ...[
                    const Text(
                      'Notificaciones',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    for (final n in state.notifications.take(5))
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.notifications_outlined),
                          title: Text(n.message),
                          subtitle: Text(n.createdAt.toLocal().toString()),
                        ),
                      ),
                    const SizedBox(height: 12),
                  ],
                  const Text(
                    'Historial',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  if (state.history.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text('No hay nóminas pagadas todavía.'),
                      ),
                    )
                  else
                    for (final it in state.history)
                      Card(
                        child: ListTile(
                          title: Text(
                            '${it.period.year}-${it.period.month.toString().padLeft(2, '0')} (${_halfLabel(it.period.half)})',
                          ),
                          subtitle: Text(
                            'Neto: ${it.netAmount.toStringAsFixed(2)} • ${it.status.name.toUpperCase()}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    MyPayrollDetailScreen(runId: it.runId),
                              ),
                            );
                          },
                        ),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
