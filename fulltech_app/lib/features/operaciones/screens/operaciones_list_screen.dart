import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/module_page.dart';
import '../../auth/state/auth_providers.dart';
import '../../auth/state/auth_state.dart';
import '../../services/providers/services_provider.dart';
import '../models/operations_models.dart';
import '../constants/operations_tab_mapping.dart';
import '../state/operations_providers.dart';

class OperacionesListScreen extends ConsumerStatefulWidget {
  const OperacionesListScreen({super.key});

  @override
  ConsumerState<OperacionesListScreen> createState() =>
      _OperacionesListScreenState();
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(operationsJobsControllerProvider.notifier).refresh();
    });
  }

  bool _isTechnician(String role) =>
      role == 'tecnico' || role == 'tecnico_fijo' || role == 'contratista';

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
    final tab = OperationsTab.values[tabIndex];
    if (tab == OperationsTab.levantamientos) return 'Por levantamiento';
    if (tab == OperationsTab.mantenimiento) return 'Mantenimiento';
    if (tab == OperationsTab.instalaciones) return 'Instalación';
    if (isWarranty(job)) return 'Solución garantía';
    return 'Agendar';
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

  Color _statusColor(BuildContext context, String status) {
    final cs = Theme.of(context).colorScheme;
    switch (status) {
      case 'pending_survey':
      case 'pending_scheduling':
      case 'scheduled':
      case 'warranty_pending':
        return cs.tertiary;
      case 'survey_in_progress':
      case 'installation_in_progress':
      case 'warranty_in_progress':
        return cs.primary;
      case 'completed':
      case 'closed':
        return Colors.green.shade700;
      case 'cancelled':
        return cs.error;
      default:
        return cs.outline;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending_survey':
        return 'Pendiente';
      case 'survey_in_progress':
        return 'En proceso';
      case 'pending_scheduling':
        return 'Pendiente agenda';
      case 'scheduled':
        return 'Programado';
      case 'installation_in_progress':
        return 'En instalación';
      case 'completed':
        return 'Terminado';
      case 'warranty_pending':
        return 'Garantía pendiente';
      case 'warranty_in_progress':
        return 'Garantía en proceso';
      case 'closed':
        return 'Cerrado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return status;
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
    final isTech =
        _isTechnician(role) || role == 'admin' || role == 'administrador';

    final state = ref.watch(operationsJobsControllerProvider);

    final techsAsync = ref.watch(operationsTechniciansProvider);

    return DefaultTabController(
      length: OperationsTab.values.length,
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
                          labelText: 'Buscar (cliente, tel., dirección, id...)',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 280,
                      child: DropdownButtonFormField<String?>(
                        initialValue: state.status,
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
                            value: 'pending_survey',
                            child: Text('Pendiente levantamiento'),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'survey_in_progress',
                            child: Text('Levantamiento en proceso'),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'pending_scheduling',
                            child: Text('Pendiente agenda'),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'scheduled',
                            child: Text('Programado'),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'installation_in_progress',
                            child: Text('Instalación en progreso'),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'completed',
                            child: Text('Completado'),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'warranty_pending',
                            child: Text('Garantía pendiente'),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'warranty_in_progress',
                            child: Text('Garantía en progreso'),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'closed',
                            child: Text('Cerrado'),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'cancelled',
                            child: Text('Cancelado'),
                          ),
                        ],
                        onChanged: (v) => ref
                            .read(operationsJobsControllerProvider.notifier)
                            .setStatus(v),
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
                    SizedBox(
                      width: 320,
                      child: ref
                          .watch(activeServicesProvider)
                          .when(
                            data: (services) {
                              return DropdownButtonFormField<String?>(
                                initialValue: state.serviceId,
                                decoration: const InputDecoration(
                                  labelText: 'Servicio',
                                  prefixIcon: Icon(Icons.build_outlined),
                                ),
                                isExpanded: true,
                                items: [
                                  const DropdownMenuItem<String?>(
                                    value: null,
                                    child: Text('Todos'),
                                  ),
                                  ...services.map(
                                    (s) => DropdownMenuItem<String?>(
                                      value: s.id,
                                      child: Text(s.name),
                                    ),
                                  ),
                                ],
                                onChanged: (v) => ref
                                    .read(
                                      operationsJobsControllerProvider.notifier,
                                    )
                                    .setServiceId(v),
                              );
                            },
                            loading: () => const LinearProgressIndicator(),
                            error: (e, st) {
                              debugPrint('[OPS] services load failed: $e');
                              debugPrintStack(stackTrace: st);
                              return const Text(
                                'No se pudieron cargar servicios',
                              );
                            },
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
            const SizedBox(height: 8),
            TabBar(
              isScrollable: true,
              tabs: List.generate(
                OperationsTab.values.length,
                (i) => Tab(text: _tabLabel(i)),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
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
                      if (OperationsTab.values[tabIndex] == OperationsTab.agenda) ...[
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
                              final typeLabel = _typeLabelFor(tabIndex, job);
                              final statusLabel = _statusLabel(job.status);
                              final statusColor = _statusColor(
                                context,
                                job.status,
                              );
                              final localDate = job.scheduledDate?.toLocal();
                              final dateStr = (localDate == null)
                                  ? null
                                  : MaterialLocalizations.of(
                                      context,
                                    ).formatCompactDate(localDate);
                              final timeStr =
                                  (job.preferredTime != null &&
                                      job.preferredTime!.trim().isNotEmpty)
                                  ? job.preferredTime!.trim()
                                  : null;

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

                              final subtitleParts = <String>[];
                              if (job.customerPhone != null &&
                                  job.customerPhone!.trim().isNotEmpty) {
                                subtitleParts.add(job.customerPhone!.trim());
                              }
                              if (job.crmChatId != null &&
                                  job.crmChatId!.trim().isNotEmpty) {
                                subtitleParts.add(
                                  'Chat: ${job.crmChatId!.trim()}',
                                );
                              }
                              if (job.serviceType.trim().isNotEmpty) {
                                subtitleParts.add(
                                  'Servicio: ${job.serviceType.trim()}',
                                );
                              }
                              if (dateStr != null)
                                subtitleParts.add('Agenda: $dateStr');
                              if (timeStr != null) subtitleParts.add(timeStr);
                              if (techLine != null)
                                subtitleParts.add('Téc: $techLine');
                              if (job.notes != null &&
                                  job.notes!.trim().isNotEmpty) {
                                subtitleParts.add('Nota: ${job.notes!.trim()}');
                              }
                              if (job.customerAddress != null &&
                                  job.customerAddress!.trim().isNotEmpty) {
                                subtitleParts.add(job.customerAddress!.trim());
                              }

                              return Card(
                                child: ListTile(
                                  leading: Icon(
                                    Icons.event_outlined,
                                    color: statusColor,
                                  ),
                                  title: Text(
                                    job.customerName.trim().isNotEmpty
                                        ? job.customerName.trim()
                                        : 'Cliente',
                                  ),
                                  subtitle: Text(subtitleParts.join(' • ')),
                                  trailing: Wrap(
                                    spacing: 8,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Chip(label: Text(typeLabel)),
                                      Chip(
                                        label: Text(statusLabel),
                                        backgroundColor: statusColor.withValues(
                                          alpha: 0.12,
                                        ),
                                        side: BorderSide(color: statusColor),
                                      ),
                                      IconButton(
                                        tooltip: 'Abrir',
                                        onPressed: () => context.go(
                                          AppRoutes.operacionesDetail(job.id),
                                        ),
                                        icon: const Icon(Icons.chevron_right),
                                      ),
                                    ],
                                  ),
                                  onTap: () => context.go(
                                    AppRoutes.operacionesDetail(job.id),
                                  ),
                                ),
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
                                padding: const EdgeInsets.only(
                                  bottom: 8,
                                  top: 8,
                                ),
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
                                final typeLabel = _typeLabelFor(tabIndex, job);
                                final statusLabel = _statusLabel(job.status);
                                final statusColor = _statusColor(
                                  context,
                                  job.status,
                                );
                                final localDate = job.scheduledDate?.toLocal();
                                final dateStr = (localDate == null)
                                    ? null
                                    : MaterialLocalizations.of(
                                        context,
                                      ).formatCompactDate(localDate);
                                final timeStr =
                                    (job.preferredTime != null &&
                                        job.preferredTime!.trim().isNotEmpty)
                                    ? job.preferredTime!.trim()
                                    : null;

                                String? techLine;
                                if (job.assignedTechId != null &&
                                    job.assignedTechId!.trim().isNotEmpty) {
                                  techLine = techsAsync.when(
                                    data: (techs) => _techNameById(
                                      techs,
                                      job.assignedTechId!,
                                    ),
                                    loading: () => job.assignedTechId,
                                    error: (_, __) => job.assignedTechId,
                                  );
                                }

                                final subtitleParts = <String>[];
                                if (job.serviceType.trim().isNotEmpty) {
                                  subtitleParts.add(job.serviceType.trim());
                                }
                                if (job.customerPhone != null &&
                                    job.customerPhone!.trim().isNotEmpty) {
                                  subtitleParts.add(job.customerPhone!.trim());
                                }
                                if (job.customerAddress != null &&
                                    job.customerAddress!.trim().isNotEmpty) {
                                  subtitleParts.add(
                                    job.customerAddress!.trim(),
                                  );
                                }
                                if (dateStr != null) subtitleParts.add(dateStr);
                                if (timeStr != null) subtitleParts.add(timeStr);
                                if (techLine != null)
                                  subtitleParts.add('Téc: $techLine');

                                return Card(
                                  child: ListTile(
                                    leading: Icon(
                                      OperationsTab.values[tabIndex] ==
                                              OperationsTab.levantamientos
                                          ? Icons.assignment_turned_in_outlined
                                          : Icons.event_outlined,
                                      color: statusColor,
                                    ),
                                    title: Text(
                                      job.customerName.trim().isNotEmpty
                                          ? job.customerName.trim()
                                          : 'Cliente',
                                    ),
                                    subtitle: Text(subtitleParts.join(' • ')),
                                    trailing: Wrap(
                                      spacing: 8,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Chip(label: Text(typeLabel)),
                                        Chip(
                                          label: Text(statusLabel),
                                          backgroundColor: statusColor
                                              .withValues(alpha: 0.12),
                                          side: BorderSide(color: statusColor),
                                        ),
                                        if (job.crmChatId != null &&
                                            job.crmChatId!.trim().isNotEmpty)
                                          IconButton(
                                            tooltip: 'Abrir chat',
                                            onPressed: () => context.go(
                                              '${AppRoutes.crm}/chats/${job.crmChatId}',
                                            ),
                                            icon: const Icon(
                                              Icons.chat_bubble_outline,
                                            ),
                                          ),
                                        if (isTech)
                                          PopupMenuButton<String>(
                                            tooltip: 'Acciones',
                                            onSelected: (action) async {
                                              final repo = ref.read(
                                                operationsRepositoryProvider,
                                              );
                                              if (action == 'start') {
                                                await repo.updateJobStatus(
                                                  jobId: job.id,
                                                  status: 'EN_PROCESO',
                                                  technicianNotes: 'Iniciado',
                                                );
                                              } else if (action == 'done') {
                                                final note =
                                                    await _promptRequiredText(
                                                      context: context,
                                                      title: 'Terminar',
                                                      label:
                                                          'Resumen / resultado *',
                                                    );
                                                if (note == null) return;
                                                await repo.updateJobStatus(
                                                  jobId: job.id,
                                                  status: 'TERMINADO',
                                                  technicianNotes: note,
                                                );
                                              } else if (action == 'cancel') {
                                                final reason =
                                                    await _promptRequiredText(
                                                      context: context,
                                                      title: 'Cancelar',
                                                      label:
                                                          'Motivo de cancelación *',
                                                    );
                                                if (reason == null) return;
                                                await repo.updateJobStatus(
                                                  jobId: job.id,
                                                  status: 'CANCELADO',
                                                  cancelReason: reason,
                                                );
                                              }
                                              if (!mounted) return;
                                              await ref
                                                  .read(
                                                    operationsJobsControllerProvider
                                                        .notifier,
                                                  )
                                                  .refresh();
                                            },
                                            itemBuilder: (context) => const [
                                              PopupMenuItem(
                                                value: 'start',
                                                child: Text(
                                                  'Iniciar (En proceso)',
                                                ),
                                              ),
                                              PopupMenuItem(
                                                value: 'done',
                                                child: Text('Terminar'),
                                              ),
                                              PopupMenuItem(
                                                value: 'cancel',
                                                child: Text('Cancelar'),
                                              ),
                                            ],
                                          ),
                                        IconButton(
                                          tooltip: 'Abrir',
                                          onPressed: () => context.go(
                                            AppRoutes.operacionesDetail(job.id),
                                          ),
                                          icon: const Icon(Icons.chevron_right),
                                        ),
                                      ],
                                    ),
                                    onTap: () => context.go(
                                      AppRoutes.operacionesDetail(job.id),
                                    ),
                                  ),
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
      ),
    );
  }
}
