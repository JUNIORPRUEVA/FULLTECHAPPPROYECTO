import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/module_page.dart';
import '../state/operations_providers.dart';

class OperacionesListScreen extends ConsumerStatefulWidget {
  const OperacionesListScreen({super.key});

  @override
  ConsumerState<OperacionesListScreen> createState() => _OperacionesListScreenState();
}

class _OperacionesListScreenState extends ConsumerState<OperacionesListScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(operationsJobsControllerProvider.notifier).refresh());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(operationsJobsControllerProvider);

    return ModulePage(
      title: 'Operaciones',
      actions: [
        IconButton(
          tooltip: 'Refrescar',
          onPressed: () => ref.read(operationsJobsControllerProvider.notifier).refresh(),
          icon: const Icon(Icons.refresh),
        ),
      ],
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 320,
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => ref.read(operationsJobsControllerProvider.notifier).setSearch(v),
                      decoration: const InputDecoration(
                        labelText: 'Buscar (cliente, teléfono, dirección, servicio...)',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 260,
                    child: DropdownButtonFormField<String>(
                      value: state.status,
                      decoration: const InputDecoration(
                        labelText: 'Estado',
                        prefixIcon: Icon(Icons.flag_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Todos')),
                        DropdownMenuItem(value: 'pending_survey', child: Text('Pendiente levantamiento')),
                        DropdownMenuItem(value: 'pending_scheduling', child: Text('Pendiente agenda')),
                        DropdownMenuItem(value: 'scheduled', child: Text('Programado')),
                        DropdownMenuItem(value: 'installation_in_progress', child: Text('Instalación en progreso')),
                        DropdownMenuItem(value: 'completed', child: Text('Completado')),
                        DropdownMenuItem(value: 'warranty_pending', child: Text('Garantía pendiente')),
                        DropdownMenuItem(value: 'warranty_in_progress', child: Text('Garantía en progreso')),
                        DropdownMenuItem(value: 'closed', child: Text('Cerrado')),
                        DropdownMenuItem(value: 'cancelled', child: Text('Cancelado')),
                      ],
                      onChanged: (v) => ref.read(operationsJobsControllerProvider.notifier).setStatus(v),
                    ),
                  ),
                  if (state.error != null)
                    Text(
                      state.error!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Card(
              child: Builder(
                builder: (context) {
                  if (state.loading && state.items.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.items.isEmpty) {
                    return const Center(child: Text('Sin trabajos'));
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: state.items.length + (state.hasMore ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      if (i >= state.items.length) {
                        return Align(
                          alignment: Alignment.center,
                          child: FilledButton.icon(
                            onPressed: state.loading
                                ? null
                                : () => ref.read(operationsJobsControllerProvider.notifier).loadMore(),
                            icon: state.loading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.expand_more),
                            label: const Text('Cargar más'),
                          ),
                        );
                      }

                      final job = state.items[i];
                        final title = job.customerName.trim().isNotEmpty
                          ? job.customerName.trim()
                          : 'Cliente';
                      final subtitleParts = <String>[
                        job.serviceType,
                        if (job.customerPhone != null && job.customerPhone!.trim().isNotEmpty)
                          job.customerPhone!.trim(),
                        job.status,
                      ];

                      return ListTile(
                        leading: const Icon(Icons.assignment_outlined),
                        title: Text(title),
                        subtitle: Text(subtitleParts.join(' • ')),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.go(AppRoutes.operacionesDetail(job.id)),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
