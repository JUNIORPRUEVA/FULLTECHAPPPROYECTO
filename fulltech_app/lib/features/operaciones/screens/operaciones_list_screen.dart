import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/module_page.dart';
import '../state/operations_providers.dart';

class OperacionesListScreen extends ConsumerStatefulWidget {
  const OperacionesListScreen({super.key});

  @override
  ConsumerState<OperacionesListScreen> createState() =>
      _OperacionesListScreenState();
}

class _OperacionesListScreenState extends ConsumerState<OperacionesListScreen> {
  final _searchCtrl = TextEditingController();

  static const _agendaStatuses = <String>{
    'SERVICIO_RESERVADO',
    'POR_LEVANTAMIENTO',
    'SOLUCION_GARANTIA',
    // Backward compatible legacy mapping
    'pending_survey',
  };

  static const _instalacionesStatuses = <String>{
    'INSTALACION_PENDIENTE',
    'INSTALACION_FINALIZADA',
    // Backward compatible legacy mapping
    'scheduled',
    'installation_in_progress',
    'completed',
  };

  static const _pendientesStatuses = <String>{
    'RESERVA',
    'EN_GARANTIA',
    // Backward compatible legacy mapping
    'pending_scheduling',
    'warranty_pending',
    'warranty_in_progress',
  };

  String _statusLabel(String raw) {
    switch (raw) {
      case 'POR_LEVANTAMIENTO':
        return 'Por levantamiento';
      case 'SERVICIO_RESERVADO':
        return 'Servicio reservado';
      case 'SOLUCION_GARANTIA':
        return 'Solución de garantía';
      case 'INSTALACION_PENDIENTE':
        return 'Instalación pendiente';
      case 'INSTALACION_FINALIZADA':
        return 'Instalación finalizada';
      case 'RESERVA':
        return 'Reserva';
      case 'EN_GARANTIA':
        return 'En garantía';

      // Legacy fallbacks
      case 'pending_survey':
        return 'Pendiente levantamiento';
      case 'pending_scheduling':
        return 'Pendiente agenda';
      case 'scheduled':
        return 'Programado';
      case 'installation_in_progress':
        return 'Instalación en progreso';
      case 'completed':
        return 'Completado';
      case 'warranty_pending':
        return 'Garantía pendiente';
      case 'warranty_in_progress':
        return 'Garantía en progreso';
      default:
        return raw;
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(operationsJobsControllerProvider.notifier).refresh(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(operationsJobsControllerProvider);

    final allItems = state.items;
    List<dynamic> filterByTab(int tabIndex) {
      final wanted = switch (tabIndex) {
        0 => _pendientesStatuses,
        1 => _instalacionesStatuses,
        _ => _agendaStatuses,
      };
      return allItems
          .where((j) => wanted.contains((j.status).toString()))
          .toList();
    }

    Widget buildList(List items) {
      if (state.loading && allItems.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (items.isEmpty) {
        return const Center(child: Text('Sin trabajos'));
      }

      return ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: items.length + (state.hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          if (i >= items.length) {
            return Align(
              alignment: Alignment.center,
              child: FilledButton.icon(
                onPressed: state.loading
                    ? null
                    : () => ref
                          .read(operationsJobsControllerProvider.notifier)
                          .loadMore(),
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

          final job = items[i];
          final title = job.customerName.trim().isNotEmpty
              ? job.customerName.trim()
              : 'Cliente';
          final subtitleParts = <String>[
            job.serviceType,
            if (job.customerPhone != null &&
                job.customerPhone!.trim().isNotEmpty)
              job.customerPhone!.trim(),
            _statusLabel(job.status),
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
    }

    return DefaultTabController(
      length: 3,
      child: ModulePage(
        title: 'Operaciones',
        actions: [
          IconButton(
            tooltip: 'Refrescar',
            onPressed: () =>
                ref.read(operationsJobsControllerProvider.notifier).refresh(),
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
                        onChanged: (v) => ref
                            .read(operationsJobsControllerProvider.notifier)
                            .setSearch(v),
                        decoration: const InputDecoration(
                          labelText:
                              'Buscar (cliente, teléfono, dirección, servicio...)',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 380,
                      child: TabBar(
                        isScrollable: true,
                        tabs: [
                          Tab(text: 'Pendientes'),
                          Tab(text: 'Instalaciones'),
                          Tab(text: 'Agenda'),
                        ],
                      ),
                    ),
                    if (state.error != null)
                      Text(
                        state.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Card(
                child: TabBarView(
                  children: [
                    Builder(builder: (context) => buildList(filterByTab(0))),
                    Builder(builder: (context) => buildList(filterByTab(1))),
                    Builder(builder: (context) => buildList(filterByTab(2))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
