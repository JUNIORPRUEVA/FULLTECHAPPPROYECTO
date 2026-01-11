import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/module_page.dart';
import '../../auth/state/auth_providers.dart';
import '../../auth/state/auth_state.dart';
import '../models/operations_models.dart';
import '../state/operations_providers.dart';

class OperacionesDetailScreen extends ConsumerWidget {
  final String? title;

  const OperacionesDetailScreen({super.key, this.title});

  static const Color _primaryDarkBlue = Color(0xFF0D47A1);

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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Modo solo lectura: no tienes permisos para realizar esta acción.',
        ),
      ),
    );
  }

  Future<String?> _promptNote({
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: ctrl,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: label,
                      errorText: error,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
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

  String _statusLabel(String status) {
    switch (status) {
      case 'pending_survey':
        return 'Pendiente levantamiento';
      case 'survey_in_progress':
        return 'Levantamiento en proceso';
      case 'survey_completed':
        return 'Levantamiento completado';
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
      case 'closed':
        return 'Cerrado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return status;
    }
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

  Future<void> _openEstadoPicker({
    required BuildContext context,
    required WidgetRef ref,
    required OperationsJob job,
    required bool canMutate,
  }) async {
    if (!canMutate) {
      _showReadOnlySnack(context);
      return;
    }

    const estados = <String>[
      'PENDIENTE',
      'PROGRAMADO',
      'EN_EJECUCION',
      'FINALIZADO',
      'CERRADO',
      'CANCELADO',
    ];

    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetCtx) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              Text(
                'Cambiar estado',
                style: Theme.of(
                  sheetCtx,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Estado actual: ${_estadoLabel(job.estado)}',
                style: Theme.of(sheetCtx).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              for (final e in estados)
                ListTile(
                  leading: Icon(
                    e == job.estado
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                    color: e == job.estado
                        ? Theme.of(sheetCtx).colorScheme.primary
                        : null,
                  ),
                  title: Text(_estadoLabel(e)),
                  onTap: () => Navigator.of(sheetCtx).pop(e),
                ),
            ],
          ),
        );
      },
    );

    if (selected == null) return;
    if (selected == job.estado) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ya está en ese estado')));
      return;
    }

    final repo = ref.read(operationsRepositoryProvider);

    if (selected == 'PROGRAMADO') {
      final picked = await showDatePicker(
        context: context,
        firstDate: DateTime.now().subtract(const Duration(days: 1)),
        lastDate: DateTime.now().add(const Duration(days: 365)),
        initialDate: DateTime.now(),
      );
      if (picked == null) return;
      final iso =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      await repo.programarOperacion(
        jobId: job.id,
        scheduledDate: iso,
        assignedTechId: job.assignedTechId,
      );
    } else if (selected == 'FINALIZADO') {
      final note = await _promptNote(
        context: context,
        title: 'Finalizar',
        label: 'Resumen / resultado *',
      );
      if (note == null) return;
      await repo.patchOperacionEstado(
        jobId: job.id,
        estado: selected,
        note: note,
      );
    } else if (selected == 'CANCELADO') {
      final reason = await _promptNote(
        context: context,
        title: 'Cancelar',
        label: 'Motivo de cancelación *',
      );
      if (reason == null) return;
      await repo.patchOperacionEstado(
        jobId: job.id,
        estado: selected,
        note: reason,
      );
    } else {
      await repo.patchOperacionEstado(jobId: job.id, estado: selected);
    }

    ref.invalidate(operationsJobDetailProvider(job.id));
    ref.invalidate(operationsJobHistoryProvider(job.id));
    // ignore: unawaited_futures
    ref.read(operationsJobsControllerProvider.notifier).refresh();
  }

  String _fmtDateTime(BuildContext context, DateTime dt) {
    final d = MaterialLocalizations.of(context).formatCompactDate(dt.toLocal());
    final t = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(dt.toLocal()),
      alwaysUse24HourFormat: false,
    );
    return '$d $t';
  }

  Future<void> _openMaps({
    required BuildContext context,
    required double? lat,
    required double? lng,
    required String? address,
  }) async {
    Uri? uri;
    if (lat != null && lng != null) {
      uri = Uri.parse('https://www.google.com/maps?q=$lat,$lng');
    } else if (address != null && address.trim().isNotEmpty) {
      uri = Uri.parse(
        'https://www.google.com/maps?q=${Uri.encodeComponent(address.trim())}',
      );
    }

    if (uri == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ubicación no disponible')));
      return;
    }

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir Google Maps')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobId = GoRouterState.of(context).pathParameters['id'];
    if (jobId == null || jobId.trim().isEmpty) {
      return const ModulePage(
        title: 'Operaciones',
        child: Center(child: Text('ID inválido')),
      );
    }

    final auth = ref.watch(authControllerProvider);
    final role = (auth is AuthAuthenticated) ? auth.user.role : '';
    final canMutate = _canMutateOperaciones(role);
    final canTechUpdate = canMutate;
    final canAssign = canMutate && (_isAdmin(role) || _isAssistantAdmin(role));

    final jobAsync = ref.watch(operationsJobDetailProvider(jobId));
    final historyAsync = ref.watch(operationsJobHistoryProvider(jobId));
    final warrantyAsync = ref.watch(operationsWarrantyTicketsProvider(jobId));

    return ModulePage(
      title: title ?? 'Detalle Operación',
      actions: [
        IconButton(
          tooltip: 'Refrescar',
          onPressed: () {
            ref.invalidate(operationsJobDetailProvider(jobId));
            ref.invalidate(operationsJobHistoryProvider(jobId));
            ref.invalidate(operationsWarrantyTicketsProvider(jobId));
          },
          icon: const Icon(Icons.refresh),
        ),
      ],
      child: jobAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) {
          debugPrint('[OPS] job detail load failed: $e');
          debugPrintStack(stackTrace: st);
          return const Center(child: Text('No se pudo cargar el detalle'));
        },
        data: (job) {
          final scheduleLabel = job.scheduledDate == null
              ? 'Sin fecha programada'
              : '${job.scheduledDate!.toLocal().toString().split(' ').first}'
                    '${job.preferredTime != null ? ' ${job.preferredTime}' : ''}';

          final techsAsync = ref.watch(operationsTechniciansProvider);
          String? techName;
          final techId = job.assignedTechId;
          if (techId != null && techId.trim().isNotEmpty) {
            techName = techsAsync.when(
              data: (techs) {
                for (final t in techs) {
                  if (t.id == techId) {
                    return t.telefono.trim().isEmpty
                        ? t.nombreCompleto
                        : '${t.nombreCompleto} • ${t.telefono.trim()}';
                  }
                }
                return techId;
              },
              loading: () => techId,
              error: (_, __) => techId,
            );
          }

          final locationText = (job.locationText ?? job.customerAddress)
              ?.trim();

          final hasLocation =
              (job.locationLat != null && job.locationLng != null) ||
              (locationText != null && locationText.trim().isNotEmpty);

          return ListView(
            children: [
              Card(
                clipBehavior: Clip.antiAlias,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0D47A1), Color(0xFF062A5B)],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                job.customerName,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                child: Text(
                                  job.estado.trim().isNotEmpty
                                      ? _estadoLabel(job.estado)
                                      : _statusLabel(job.status),
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (!canMutate)
                              const _HeaderPill(
                                icon: Icons.lock_outline,
                                text: 'Solo lectura',
                              ),
                            if (job.customerPhone != null &&
                                job.customerPhone!.trim().isNotEmpty)
                              _HeaderPill(
                                icon: Icons.call_outlined,
                                text: job.customerPhone!.trim(),
                              ),
                            _HeaderPill(
                              icon: Icons.design_services_outlined,
                              text: job.serviceType.trim().isEmpty
                                  ? 'Servicio'
                                  : job.serviceType.trim(),
                            ),
                            _HeaderPill(
                              icon: Icons.flag_outlined,
                              text: 'Prioridad: ${job.priority}',
                            ),
                            if (job.crmChatId != null &&
                                job.crmChatId!.trim().isNotEmpty)
                              _HeaderPill(
                                icon: Icons.forum_outlined,
                                text: 'Chat: ${job.crmChatId!.trim()}',
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 14,
                          runSpacing: 10,
                          children: [
                            _HeaderInfo(
                              icon: Icons.schedule_outlined,
                              label: 'Programación',
                              value: scheduleLabel,
                            ),
                            _HeaderInfo(
                              icon: Icons.event_available_outlined,
                              label: 'Creado',
                              value: _fmtDateTime(context, job.createdAt),
                            ),
                            if (techName != null)
                              _HeaderInfo(
                                icon: Icons.engineering_outlined,
                                label: 'Técnico',
                                value: techName,
                              ),
                            if (locationText != null &&
                                locationText.trim().isNotEmpty)
                              _HeaderInfo(
                                icon: Icons.place_outlined,
                                label: 'Ubicación',
                                value: locationText.trim(),
                              ),
                            if (job.locationLat != null &&
                                job.locationLng != null)
                              _HeaderInfo(
                                icon: Icons.my_location_outlined,
                                label: 'Coordenadas',
                                value: '${job.locationLat}, ${job.locationLng}',
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            if (hasLocation)
                              OutlinedButton.icon(
                                onPressed: () => _openMaps(
                                  context: context,
                                  lat: job.locationLat,
                                  lng: job.locationLng,
                                  address: locationText,
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.35),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                ),
                                icon: const Icon(Icons.map_outlined),
                                label: const Text('Google Maps'),
                              ),
                            if (job.crmChatId != null &&
                                job.crmChatId!.trim().isNotEmpty)
                              OutlinedButton.icon(
                                onPressed: () => context.go(
                                  '${AppRoutes.crm}/chats/${job.crmChatId}',
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.35),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                ),
                                icon: const Icon(Icons.chat_bubble_outline),
                                label: const Text('Abrir chat CRM'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Garantía',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () async {
                              if (!canTechUpdate) {
                                _showReadOnlySnack(context);
                                return;
                              }
                              final reason = await _promptNote(
                                context: context,
                                title: 'Garantía',
                                label: 'Detalle de garantía (motivo)',
                              );
                              if (reason == null || reason.trim().isEmpty) {
                                return;
                              }

                              final repo = ref.read(
                                operationsRepositoryProvider,
                              );
                              await repo.createWarrantyTicketLocalFirst(
                                jobId: jobId,
                                reason: reason.trim(),
                                assignedTechId: job.assignedTechId,
                              );

                              if (context.mounted) {
                                ref.invalidate(
                                  operationsWarrantyTicketsProvider(jobId),
                                );
                                ref.invalidate(
                                  operationsJobDetailProvider(jobId),
                                );
                              }
                            },
                            icon: Icon(
                              canTechUpdate
                                  ? Icons.add_outlined
                                  : Icons.lock_outline,
                            ),
                            label: Text(
                              canTechUpdate ? 'Agregar' : 'Agregar (bloqueado)',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      warrantyAsync.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (e, _) => Text(
                          'Error cargando garantía: $e',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        data: (tickets) {
                          if (tickets.isEmpty) {
                            return const Text('Sin garantía registrada');
                          }

                          tickets.sort(
                            (a, b) => b.reportedAt.compareTo(a.reportedAt),
                          );

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final t in tickets) ...[
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outlineVariant
                                          .withValues(alpha: 0.35),
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          'Garantía: ${t.reason}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            Chip(
                                              label: Text(switch (t.status) {
                                                'pending' => 'Pendiente',
                                                'in_progress' => 'En progreso',
                                                'resolved' => 'Resuelto',
                                                _ => t.status,
                                              }),
                                            ),
                                            Text(
                                              'Reportado: ${_fmtDateTime(context, t.reportedAt)}',
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          'Solución de garantía:',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          (t.resolutionNotes ?? '')
                                                  .trim()
                                                  .isEmpty
                                              ? 'Sin solución registrada'
                                              : t.resolutionNotes!.trim(),
                                        ),
                                        const SizedBox(height: 12),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            OutlinedButton.icon(
                                              onPressed: () async {
                                                if (!canTechUpdate) {
                                                  _showReadOnlySnack(context);
                                                  return;
                                                }
                                                final solution = await _promptNote(
                                                  context: context,
                                                  title: 'Solución de garantía',
                                                  label:
                                                      'Describe la solución aplicada',
                                                );
                                                if (solution == null ||
                                                    solution.trim().isEmpty) {
                                                  return;
                                                }

                                                final repo = ref.read(
                                                  operationsRepositoryProvider,
                                                );
                                                await repo
                                                    .patchWarrantyTicketLocalFirst(
                                                      ticketId: t.id,
                                                      jobId: jobId,
                                                      patch: {
                                                        'status': 'resolved',
                                                        'resolution_notes':
                                                            solution.trim(),
                                                        'resolved_at':
                                                            DateTime.now()
                                                                .toIso8601String(),
                                                      },
                                                    );

                                                if (context.mounted) {
                                                  ref.invalidate(
                                                    operationsWarrantyTicketsProvider(
                                                      jobId,
                                                    ),
                                                  );
                                                  ref.invalidate(
                                                    operationsJobDetailProvider(
                                                      jobId,
                                                    ),
                                                  );
                                                }
                                              },
                                              icon: Icon(
                                                canTechUpdate
                                                    ? Icons.task_alt_outlined
                                                    : Icons.lock_outline,
                                              ),
                                              label: Text(
                                                canTechUpdate
                                                    ? 'Marcar resuelta'
                                                    : 'Resuelta (bloqueado)',
                                              ),
                                            ),
                                            OutlinedButton.icon(
                                              onPressed: () async {
                                                if (!canTechUpdate) {
                                                  _showReadOnlySnack(context);
                                                  return;
                                                }
                                                final repo = ref.read(
                                                  operationsRepositoryProvider,
                                                );
                                                await repo
                                                    .patchWarrantyTicketLocalFirst(
                                                      ticketId: t.id,
                                                      jobId: jobId,
                                                      patch: {
                                                        'status': 'in_progress',
                                                      },
                                                    );
                                                if (context.mounted) {
                                                  ref.invalidate(
                                                    operationsWarrantyTicketsProvider(
                                                      jobId,
                                                    ),
                                                  );
                                                  ref.invalidate(
                                                    operationsJobDetailProvider(
                                                      jobId,
                                                    ),
                                                  );
                                                }
                                              },
                                              icon: Icon(
                                                canTechUpdate
                                                    ? Icons.play_circle_outline
                                                    : Icons.lock_outline,
                                              ),
                                              label: Text(
                                                canTechUpdate
                                                    ? 'En progreso'
                                                    : 'En progreso (bloqueado)',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              if (job.notes != null && job.notes!.trim().isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Notas (vendedor)',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(job.notes!),
                      ],
                    ),
                  ),
                ),
              if (job.technicianNotes != null &&
                  job.technicianNotes!.trim().isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Notas (técnico)',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(job.technicianNotes!),
                      ],
                    ),
                  ),
                ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      if (!canTechUpdate)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            'Modo solo lectura: cambios de estado bloqueados.',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      FilledButton.icon(
                        onPressed: () async {
                          if (!canTechUpdate) {
                            _showReadOnlySnack(context);
                            return;
                          }
                          final repo = ref.read(operationsRepositoryProvider);
                          await repo.patchOperacionEstado(
                            jobId: job.id,
                            estado: 'EN_EJECUCION',
                            note: 'Iniciado',
                          );
                          ref.invalidate(operationsJobDetailProvider(jobId));
                          ref.invalidate(operationsJobHistoryProvider(jobId));
                          // Refresh list view cache
                          // ignore: unawaited_futures
                          ref
                              .read(operationsJobsControllerProvider.notifier)
                              .refresh();
                        },
                        icon: Icon(
                          canTechUpdate ? Icons.play_arrow : Icons.lock_outline,
                        ),
                        label: Text(
                          canTechUpdate ? 'Iniciar' : 'Iniciar (bloqueado)',
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () async {
                          if (!canTechUpdate) {
                            _showReadOnlySnack(context);
                            return;
                          }
                          final note = await _promptNote(
                            context: context,
                            title: 'Terminar',
                            label: 'Resumen / resultado *',
                          );
                          if (note == null) return;
                          final repo = ref.read(operationsRepositoryProvider);
                          await repo.patchOperacionEstado(
                            jobId: job.id,
                            estado: 'FINALIZADO',
                            note: note,
                          );
                          ref.invalidate(operationsJobDetailProvider(jobId));
                          ref.invalidate(operationsJobHistoryProvider(jobId));
                          // ignore: unawaited_futures
                          ref
                              .read(operationsJobsControllerProvider.notifier)
                              .refresh();
                        },
                        icon: Icon(
                          canTechUpdate
                              ? Icons.check_circle_outline
                              : Icons.lock_outline,
                        ),
                        label: Text(
                          canTechUpdate ? 'Terminar' : 'Terminar (bloqueado)',
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          if (!canTechUpdate) {
                            _showReadOnlySnack(context);
                            return;
                          }
                          final reason = await _promptNote(
                            context: context,
                            title: 'Cancelar',
                            label: 'Motivo de cancelación *',
                          );
                          if (reason == null) return;
                          final repo = ref.read(operationsRepositoryProvider);
                          await repo.patchOperacionEstado(
                            jobId: job.id,
                            estado: 'CANCELADO',
                            note: reason,
                          );
                          ref.invalidate(operationsJobDetailProvider(jobId));
                          ref.invalidate(operationsJobHistoryProvider(jobId));
                          // ignore: unawaited_futures
                          ref
                              .read(operationsJobsControllerProvider.notifier)
                              .refresh();
                        },
                        icon: Icon(
                          canTechUpdate
                              ? Icons.cancel_outlined
                              : Icons.lock_outline,
                        ),
                        label: Text(
                          canTechUpdate ? 'Cancelar' : 'Cancelar (bloqueado)',
                        ),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () => _openEstadoPicker(
                          context: context,
                          ref: ref,
                          job: job,
                          canMutate: canTechUpdate,
                        ),
                        icon: Icon(
                          canTechUpdate
                              ? Icons.swap_horiz_outlined
                              : Icons.lock_outline,
                        ),
                        label: Text(
                          canTechUpdate
                              ? 'Cambiar estado'
                              : 'Cambiar estado (bloqueado)',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: canAssign
                      ? _AssignSection(job: job)
                      : InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _showReadOnlySnack(context),
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
                                  'Asignación (solo Admin / Asistente Administrativo).',
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Historial',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      historyAsync.when(
                        loading: () =>
                            const LinearProgressIndicator(minHeight: 2),
                        error: (e, _) => Text('Error cargando historial: $e'),
                        data: (items) {
                          if (items.isEmpty) {
                            return const Text('Sin historial');
                          }
                          return Column(
                            children: [
                              for (final it in items)
                                ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.history),
                                  title: Text(
                                    (it['action_type'] ?? '').toString(),
                                  ),
                                  subtitle: Text(
                                    [
                                          if (it['created_at'] != null)
                                            it['created_at'].toString(),
                                          if (it['note'] != null)
                                            it['note'].toString(),
                                        ]
                                        .where((s) => s.trim().isNotEmpty)
                                        .join(' • '),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeaderPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.95)),
            const SizedBox(width: 8),
            Text(
              text,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HeaderInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 220),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.95)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignSection extends ConsumerStatefulWidget {
  final OperationsJob job;

  const _AssignSection({required this.job});

  @override
  ConsumerState<_AssignSection> createState() => _AssignSectionState();
}

class _AssignSectionState extends ConsumerState<_AssignSection> {
  String? _priority;
  String? _techId;

  @override
  void initState() {
    super.initState();
    _priority = widget.job.priority;
    _techId = widget.job.assignedTechId;
  }

  @override
  Widget build(BuildContext context) {
    final api = ref.watch(operationsApiProvider);
    final auth = ref.watch(authControllerProvider);
    final role = (auth is AuthAuthenticated) ? auth.user.role : '';
    final canSave =
        auth is AuthAuthenticated &&
        (role == 'admin' ||
            role == 'administrador' ||
            role == 'asistente_administrativo');
    final techsAsync = ref.watch(operationsTechniciansProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Asignación (vendedor/admin)',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _priority ?? 'normal',
          decoration: const InputDecoration(
            labelText: 'Prioridad',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'low', child: Text('Baja')),
            DropdownMenuItem(value: 'normal', child: Text('Media')),
            DropdownMenuItem(value: 'high', child: Text('Alta')),
          ],
          onChanged: (v) => setState(() => _priority = v),
        ),
        const SizedBox(height: 12),
        techsAsync.when(
          loading: () => const LinearProgressIndicator(minHeight: 2),
          error: (e, _) => Text('Error cargando técnicos: $e'),
          data: (techs) {
            return DropdownButtonFormField<String?>(
              value: (_techId != null && _techId!.trim().isEmpty)
                  ? null
                  : _techId,
              decoration: const InputDecoration(
                labelText: 'Técnico asignado',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('-- Sin asignar --'),
                ),
                ...techs.map(
                  (t) => DropdownMenuItem<String?>(
                    value: t.id,
                    child: Text(t.nombreCompleto),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _techId = v),
            );
          },
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: OperacionesDetailScreen._primaryDarkBlue,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (!canSave) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Modo solo lectura: no tienes permisos para guardar asignación.',
                    ),
                  ),
                );
                return;
              }
              await api.patchJob(widget.job.id, {
                'priority': _priority,
                'assigned_tech_id': _techId,
              });
              ref.invalidate(operationsJobDetailProvider(widget.job.id));
              // ignore: unawaited_futures
              ref.read(operationsJobsControllerProvider.notifier).refresh();
              if (!context.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Actualizado')));
            },
            icon: const Icon(Icons.save_outlined),
            label: const Text('Guardar'),
          ),
        ),
      ],
    );
  }
}
