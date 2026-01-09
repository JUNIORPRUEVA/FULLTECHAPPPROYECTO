import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/module_page.dart';
import '../../auth/state/auth_providers.dart';
import '../../auth/state/auth_state.dart';
import '../models/operations_models.dart';
import '../state/operations_providers.dart';

class OperacionesDetailScreen extends ConsumerWidget {
  final String? title;

  const OperacionesDetailScreen({super.key, this.title});

  bool _isAdmin(String role) => role == 'admin' || role == 'administrador';
  bool _isTechnician(String role) =>
      role == 'tecnico' || role == 'tecnico_fijo' || role == 'contratista';

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
    final canTechUpdate = _isTechnician(role) || _isAdmin(role);
    final canAssign = role == 'vendedor' || _isAdmin(role);

    final jobAsync = ref.watch(operationsJobDetailProvider(jobId));
    final historyAsync = ref.watch(operationsJobHistoryProvider(jobId));

    return ModulePage(
      title: title ?? 'Detalle Operación',
      actions: [
        IconButton(
          tooltip: 'Refrescar',
          onPressed: () {
            ref.invalidate(operationsJobDetailProvider(jobId));
            ref.invalidate(operationsJobHistoryProvider(jobId));
          },
          icon: const Icon(Icons.refresh),
        ),
      ],
      child: jobAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (job) {
          final scheduleLabel = job.scheduledDate == null
              ? 'Sin fecha programada'
              : '${job.scheduledDate!.toLocal().toString().split(' ').first}'
                  '${job.preferredTime != null ? ' ${job.preferredTime}' : ''}';

          return ListView(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    runSpacing: 12,
                    spacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        job.customerName,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (job.customerPhone != null &&
                          job.customerPhone!.trim().isNotEmpty)
                        Text(job.customerPhone!),
                      const SizedBox(width: 12),
                      Chip(
                        label: Text(_statusLabel(job.status)),
                        backgroundColor: _statusColor(context, job.status)
                            .withValues(alpha: 0.12),
                        side: BorderSide(color: _statusColor(context, job.status)),
                      ),
                      const SizedBox(width: 12),
                      Chip(
                        label: Text(job.serviceType),
                      ),
                      const SizedBox(width: 12),
                      Chip(label: Text('Prioridad: ${job.priority}')),
                    ],
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
                        'Programación',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(scheduleLabel),
                      const SizedBox(height: 12),
                      if (job.crmChatId != null &&
                          job.crmChatId!.trim().isNotEmpty)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: () => context.go(
                              '${AppRoutes.crm}/chats/${job.crmChatId}',
                            ),
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: const Text('Abrir chat CRM'),
                          ),
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
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
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
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(job.technicianNotes!),
                      ],
                    ),
                  ),
                ),
              if (canTechUpdate)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton.icon(
                          onPressed: () async {
                            final repo =
                                ref.read(operationsRepositoryProvider);
                            await repo.updateJobStatus(
                              jobId: job.id,
                              status: 'EN_PROCESO',
                              technicianNotes: 'Iniciado',
                            );
                            ref.invalidate(operationsJobDetailProvider(jobId));
                            ref.invalidate(operationsJobHistoryProvider(jobId));
                            // Refresh list view cache
                            // ignore: unawaited_futures
                            ref
                                .read(operationsJobsControllerProvider.notifier)
                                .refresh();
                          },
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Iniciar'),
                        ),
                        FilledButton.icon(
                          onPressed: () async {
                            final note = await _promptNote(
                              context: context,
                              title: 'Terminar',
                              label: 'Resumen / resultado *',
                            );
                            if (note == null) return;
                            final repo =
                                ref.read(operationsRepositoryProvider);
                            await repo.updateJobStatus(
                              jobId: job.id,
                              status: 'TERMINADO',
                              technicianNotes: note,
                            );
                            ref.invalidate(operationsJobDetailProvider(jobId));
                            ref.invalidate(operationsJobHistoryProvider(jobId));
                            // ignore: unawaited_futures
                            ref
                                .read(operationsJobsControllerProvider.notifier)
                                .refresh();
                          },
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Terminar'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final reason = await _promptNote(
                              context: context,
                              title: 'Cancelar',
                              label: 'Motivo de cancelación *',
                            );
                            if (reason == null) return;
                            final repo =
                                ref.read(operationsRepositoryProvider);
                            await repo.updateJobStatus(
                              jobId: job.id,
                              status: 'CANCELADO',
                              cancelReason: reason,
                            );
                            ref.invalidate(operationsJobDetailProvider(jobId));
                            ref.invalidate(operationsJobHistoryProvider(jobId));
                            // ignore: unawaited_futures
                            ref
                                .read(operationsJobsControllerProvider.notifier)
                                .refresh();
                          },
                          icon: const Icon(Icons.cancel_outlined),
                          label: const Text('Cancelar'),
                        ),
                      ],
                    ),
                  ),
                ),
              if (canAssign)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _AssignSection(job: job),
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
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
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
                                    ].where((s) => s.trim().isNotEmpty).join(' • '),
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
    final canSave = auth is AuthAuthenticated;
    final techsAsync = ref.watch(operationsTechniciansProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Asignación (vendedor/admin)',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
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
              value: (_techId != null && _techId!.trim().isEmpty) ? null : _techId,
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
            onPressed: !canSave
                ? null
                : () async {
                    await api.patchJob(widget.job.id, {
                      'priority': _priority,
                      'assigned_tech_id': _techId,
                    });
                    ref.invalidate(operationsJobDetailProvider(widget.job.id));
                    // ignore: unawaited_futures
                    ref
                        .read(operationsJobsControllerProvider.notifier)
                        .refresh();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Actualizado')),
                    );
                  },
            icon: const Icon(Icons.save_outlined),
            label: const Text('Guardar'),
          ),
        ),
      ],
    );
  }
}
