import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/module_page.dart';
import '../../auth/state/auth_providers.dart';
import '../../auth/state/auth_state.dart';
import '../models/operations_models.dart';
import '../constants/operations_tab_mapping.dart';
import '../state/operations_providers.dart';
import '../presentation/widgets/operation_card_compact.dart';

class OperacionesListScreen extends ConsumerStatefulWidget {
  const OperacionesListScreen({super.key});

  @override
  ConsumerState<OperacionesListScreen> createState() =>
      _OperacionesListScreenState();
}

class _OperacionesListScreenState extends ConsumerState<OperacionesListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchCtrl = TextEditingController();

  static const String _readOnlyMessage =
      'Modo solo lectura: no tienes permisos para modificar Operaciones.';

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: OperationsTab.values.length,
      vsync: this,
    );

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final tab = OperationsTab.values[_tabController.index];
        ref.read(operationsJobsControllerProvider.notifier).applyTabPreset(tab);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(operationsJobsControllerProvider.notifier).refresh();
    });
  }

  bool _isAdmin(String role) => role == 'admin' || role == 'administrador';
  bool _isAssistantAdmin(String role) => role == 'asistente_administrativo';

  // Technician roles allowed to perform actions in Operaciones.
  // NOTE: Keep legacy 'tecnico' but exclude 'contratista' as requested.
  bool _isTechnician(String role) =>
      role == 'tecnico' || role == 'tecnico_fijo';

  bool _canMutateOperaciones(String role) {
    return _isAdmin(role) || _isTechnician(role) || _isAssistantAdmin(role);
  }

  void _showReadOnlySnack(BuildContext context) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(const SnackBar(content: Text(_readOnlyMessage)));
  }

  Widget _guardedAction({
    required BuildContext context,
    required bool allowed,
    required Widget child,
  }) {
    if (allowed) return child;
    return Tooltip(
      message: 'Solo lectura',
      child: Stack(
        children: [
          Opacity(opacity: 0.45, child: IgnorePointer(child: child)),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showReadOnlySnack(context),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _tabLabel(int index) {
    return operationsTabLabel(OperationsTab.values[index]);
  }

  bool _matchesTab(int index, OperationsJob job) {
    return jobMatchesTab(OperationsTab.values[index], job);
  }

  DateTime? _effectiveDate(OperationsJob job) {
    return job.scheduledDate?.toLocal() ?? job.createdAt.toLocal();
  }

  DateTime? _effectiveDay(OperationsJob job) {
    final date = _effectiveDate(job);
    if (date == null) return null;
    return DateTime(date.year, date.month, date.day);
  }

  String _typeLabelFor(int tabIndex, OperationsJob job) {
    final tipo = job.tipoTrabajo.trim().toUpperCase();
    switch (tipo) {
      case 'LEVANTAMIENTO':
        return 'Levantamiento';
      case 'GARANTIA':
        return 'Garantía';
      case 'MANTENIMIENTO':
        return 'Mantenimiento';
      case 'INSTALACION':
      default:
        return 'Instalación';
    }
  }

  String _techNameById(List<dynamic> techs, String id) {
    for (final t in techs) {
      try {
        if ((t.id ?? '').toString() == id) {
          final name = (t.nombreCompleto ?? '').toString().trim();
          return name.isNotEmpty ? name : id;
        }
      } catch (_) {
        // ignore
      }
    }
    return id;
  }

  Color _estadoColor(BuildContext context, String estado) {
    final cs = Theme.of(context).colorScheme;
    final e = estado.trim().toUpperCase();
    if (e == 'CANCELADO') return cs.error;
    if (e == 'FINALIZADO' || e == 'CERRADO') return Colors.green.shade700;
    // Corporate dark blue badge for active states
    return const Color(0xFF0D47A1);
  }

  String _estadoLabel(String estado) {
    switch (estado.trim().toUpperCase()) {
      case 'PENDIENTE':
        return 'Pendiente';
      case 'PROGRAMADO':
        return 'Programado';
      case 'EN_EJECUCION':
        return 'En ejecución';
      case 'FINALIZADO':
        return 'Finalizado';
      case 'CERRADO':
        return 'Cerrado';
      case 'CANCELADO':
        return 'Cancelado';
      default:
        return estado;
    }
  }

  Future<String?> _promptRequiredText({
    required BuildContext context,
    required String title,
    required String label,
  }) async {
    final ctrl = TextEditingController();
    String? error;
    final res = await showDialog<String?>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setState) {
          return AlertDialog(
            title: Text(title),
            content: SizedBox(
              width: 520,
              child: TextField(
                controller: ctrl,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: label,
                  errorText: error,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(null),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  final v = ctrl.text.trim();
                  if (v.isEmpty) {
                    setState(() => error = 'Este campo es requerido');
                    return;
                  }
                  Navigator.of(dialogCtx).pop(v);
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
    ctrl.dispose();
    return res;
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final role = (auth is AuthAuthenticated) ? auth.user.role : '';
    final isAdmin = _isAdmin(role);
    final isTechRole = _isTechnician(role);
    final isAssistantAdmin = _isAssistantAdmin(role);
    final canMutate = _canMutateOperaciones(role);

    // Office actions: schedule/convert/close (admin + assistant admin)
    final canOfficeActions = canMutate && (isAdmin || isAssistantAdmin);
    // Technician actions: start/finish/cancel (admin + technician)
    final canTechActions = canMutate && (isAdmin || isTechRole);

    final state = ref.watch(operationsJobsControllerProvider);

    final techsAsync = ref.watch(operationsTechniciansProvider);

    return ModulePage(
      title: 'Operaciones',
      actions: [
        IconButton(
          tooltip: 'Agenda / Levantamientos (CRM)',
          onPressed: () => context.go(AppRoutes.operacionesAgenda),
          icon: const Icon(Icons.event_note),
        ),
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
                  if (!canMutate)
                    SizedBox(
                      width: double.infinity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.outlineVariant.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.lock_outline,
                                size: 18,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Modo solo lectura: puedes ver Operaciones, pero no tienes permisos para modificar (cambiar estado, programar o cerrar).',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  SizedBox(
                    width: 320,
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => ref
                          .read(operationsJobsControllerProvider.notifier)
                          .setSearch(v),
                      decoration: const InputDecoration(
                        labelText: 'Buscar (cliente, tel., dirección, id...)',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 280,
                    child: DropdownButtonFormField<String?>(
                      initialValue: state.estado,
                      decoration: const InputDecoration(
                        labelText: 'Estado',
                        prefixIcon: Icon(Icons.flag_outlined),
                      ),
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Todos'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'PENDIENTE',
                          child: Text('Pendiente'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'PROGRAMADO',
                          child: Text('Programado'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'EN_EJECUCION',
                          child: Text('En ejecución'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'FINALIZADO',
                          child: Text('Finalizado'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'CERRADO',
                          child: Text('Cerrado'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'CANCELADO',
                          child: Text('Cancelado'),
                        ),
                      ],
                      onChanged: (v) => ref
                          .read(operationsJobsControllerProvider.notifier)
                          .setEstado(v),
                    ),
                  ),
                  SizedBox(
                    width: 260,
                    child: DropdownButtonFormField<String?>(
                      initialValue: state.tipoTrabajo,
                      decoration: const InputDecoration(
                        labelText: 'Tipo',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Todos'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'INSTALACION',
                          child: Text('Instalación'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'MANTENIMIENTO',
                          child: Text('Mantenimiento'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'LEVANTAMIENTO',
                          child: Text('Levantamiento'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'GARANTIA',
                          child: Text('Garantía'),
                        ),
                      ],
                      onChanged: (v) => ref
                          .read(operationsJobsControllerProvider.notifier)
                          .setTipoTrabajo(v),
                    ),
                  ),
                  SizedBox(
                    width: 320,
                    child: techsAsync.when(
                      data: (techs) {
                        return DropdownButtonFormField<String?>(
                          initialValue: state.assignedTechId,
                          decoration: const InputDecoration(
                            labelText: 'Técnico',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Todos'),
                            ),
                            ...techs.map(
                              (t) => DropdownMenuItem<String?>(
                                value: t.id,
                                child: Text(
                                  t.telefono.trim().isEmpty
                                      ? t.nombreCompleto
                                      : '${t.nombreCompleto} • ${t.telefono.trim()}',
                                ),
                              ),
                            ),
                          ],
                          onChanged: (v) => ref
                              .read(operationsJobsControllerProvider.notifier)
                              .setAssignedTechId(v),
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (e, st) {
                        debugPrint('[OPS] technicians load failed: $e');
                        debugPrintStack(stackTrace: st);
                        return const Text('No se pudieron cargar técnicos');
                      },
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => ref
                            .read(operationsJobsControllerProvider.notifier)
                            .quickToday(),
                        icon: const Icon(Icons.today_outlined),
                        label: const Text('Hoy'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => ref
                            .read(operationsJobsControllerProvider.notifier)
                            .quickThisWeek(),
                        icon: const Icon(Icons.date_range_outlined),
                        label: const Text('Esta semana'),
                      ),
                      TextButton(
                        onPressed: () => ref
                            .read(operationsJobsControllerProvider.notifier)
                            .clearDateRange(),
                        child: const Text('Todas'),
                      ),
                    ],
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
          const SizedBox(height: 8),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: List.generate(
              OperationsTab.values.length,
              (i) => Tab(text: _tabLabel(i)),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(OperationsTab.values.length, (tabIndex) {
                final filtered = state.items
                    .where((j) => _matchesTab(tabIndex, j))
                    .toList();

                // Group Agenda tab by Today / Upcoming (and keep a fallback for items with no date).
                final today = DateTime.now();
                final todayDay = DateTime(today.year, today.month, today.day);

                final groups = <String, List<OperationsJob>>{
                  'Hoy': <OperationsJob>[],
                  'Próximos': <OperationsJob>[],
                  'Sin fecha': <OperationsJob>[],
                };
                if (OperationsTab.values[tabIndex] == OperationsTab.agenda) {
                  for (final j in filtered) {
                    final day = _effectiveDay(j);
                    if (day == null) {
                      groups['Sin fecha']!.add(j);
                    } else if (day == todayDay) {
                      groups['Hoy']!.add(j);
                    } else {
                      groups['Próximos']!.add(j);
                    }
                  }
                }

                if (state.loading && state.items.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (filtered.isEmpty) {
                  return const Center(child: Text('Sin tareas'));
                }

                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    if (OperationsTab.values[tabIndex] ==
                        OperationsTab.agenda) ...[
                      for (final section in const [
                        'Hoy',
                        'Próximos',
                        'Sin fecha',
                      ]) ...[
                        if (groups[section]!.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8, top: 8),
                            child: Text(
                              section,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          ...(() {
                            final list = groups[section]!
                              ..sort((a, b) {
                                final da = _effectiveDate(a) ?? a.createdAt;
                                final db = _effectiveDate(b) ?? b.createdAt;
                                return da.compareTo(db);
                              });
                            return list;
                          })().map((job) {
                            String? techLine;
                            if (job.assignedTechId != null &&
                                job.assignedTechId!.trim().isNotEmpty) {
                              techLine = techsAsync.when(
                                data: (techs) =>
                                    _techNameById(techs, job.assignedTechId!),
                                loading: () => job.assignedTechId,
                                error: (_, __) => job.assignedTechId,
                              );
                            }

                            return OperationCardCompact(
                              job: job,
                              technicianName: techLine,
                              canMutate: canMutate,
                              canOfficeActions: canOfficeActions,
                              canTechActions: canTechActions,
                              onRefresh: () => ref
                                  .read(
                                    operationsJobsControllerProvider.notifier,
                                  )
                                  .refresh(),
                            );
                          }),
                        ],
                      ],
                    ] else ...[
                      // Keep existing per-day grouping for other tabs.
                      ...(() {
                        final map = <DateTime?, List<OperationsJob>>{};
                        for (final j in filtered) {
                          final day = _effectiveDay(j);
                          map.putIfAbsent(day, () => []).add(j);
                        }
                        final keys = map.keys.toList()
                          ..sort((a, b) {
                            if (a == null && b == null) return 0;
                            if (a == null) return 1;
                            if (b == null) return -1;
                            return a.compareTo(b);
                          });
                        for (final k in keys) {
                          map[k]!.sort((a, b) {
                            final da = _effectiveDate(a) ?? a.createdAt;
                            final db = _effectiveDate(b) ?? b.createdAt;
                            return da.compareTo(db);
                          });
                        }

                        return <Widget>[
                          for (final day in keys) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8, top: 8),
                              child: Text(
                                day == null
                                    ? 'Sin fecha'
                                    : MaterialLocalizations.of(
                                        context,
                                      ).formatFullDate(day),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            ...map[day]!.map((job) {
                              String? techLine;
                              if (job.assignedTechId != null &&
                                  job.assignedTechId!.trim().isNotEmpty) {
                                techLine = techsAsync.when(
                                  data: (techs) =>
                                      _techNameById(techs, job.assignedTechId!),
                                  loading: () => job.assignedTechId,
                                  error: (_, __) => job.assignedTechId,
                                );
                              }

                              return OperationCardCompact(
                                job: job,
                                technicianName: techLine,
                                canMutate: canMutate,
                                canOfficeActions: canOfficeActions,
                                canTechActions: canTechActions,
                                onRefresh: () => ref
                                    .read(
                                      operationsJobsControllerProvider.notifier,
                                    )
                                    .refresh(),
                              );
                            }),
                          ],
                        ];
                      })(),
                    ],
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
